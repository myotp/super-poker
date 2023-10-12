defmodule SuperPoker.Bot.PlayerBotServer do
  use GenServer
  require Logger

  alias SuperPoker.Table

  alias SuperPoker.Bot.NaiveCallBot

  @moduledoc """
  这里, 争取从API层面, 从实现层面乱入PlayerServer对应的
  那样的话, 就可以从派发消息的角度, 形成一个Player但是多个不同类型的GenServer派发了
  比如可以PlayerServer与这里的PlayerBotServer都是同一份API与回调
  但是, 完全可以做出不同的处理来

  启动与停止
  这里的现在bot进程, 设计的是玩家加入桌子后, 可以激活一个bot玩家加入
  所以, 如果bot加入不了桌子, 则自然终止进程
  如果桌子仅剩bot自己, 则同样自然终止进程

  username层级
  这个进程维持住自己的username, 这样

  bot
  有了基础bot实现之后, 提取出来尽量多的内容到纯函数式的bot当中
  这样, 后续就可以可替换的实现不同类型的bot, 并且易于测试
  """
  defmodule State do
    defstruct [
      :username,
      :table_id,
      :bot_mod,
      :bot
    ]
  end

  def start_bot(table_id) do
    bot_mod = choose_bot_strategy()
    do_start_bot(table_id, bot_mod)
  end

  defp choose_bot_strategy() do
    Enum.random([NaiveCallBot])
  end

  def do_start_bot(table_id, bot_mod) do
    username = bot_mod.random_username()
    # 都挂在同样的PlayerSupervisor旗下, 但是是不同的模块实现
    DynamicSupervisor.start_child(
      SuperPoker.Player.PlayerSupervisor,
      {__MODULE__, [username, table_id, bot_mod]}
    )
  end

  # ================ GenServer回调部分 =======================
  def start_link([username, table_id, bot_mod]) do
    IO.puts("启动bot #{username} 加入桌子#{table_id}")
    GenServer.start_link(__MODULE__, [username, table_id, bot_mod], name: via_tuple(username))
  end

  # FIXME: 这里, 作为多态GenServer关键, 此函数移入上层
  defp via_tuple(username) do
    {:via, Registry, {SuperPoker.Player.PlayerRegistry, username}}
  end

  @impl GenServer
  def init([username, table_id, bot_mod]) do
    log("对于bot#{username}启动独立player进程")

    state = %State{
      username: username,
      table_id: table_id,
      bot_mod: bot_mod,
      bot: nil
    }

    {:ok, state, {:continue, :will_join_table}}
  end

  @impl GenServer
  def handle_call(
        {:deal_hole_cards, hole_cards},
        _from,
        %State{username: username, bot_mod: bot_mod, bot: bot} = state
      ) do
    log("bot#{username}收到手牌 #{inspect(hole_cards)}")
    bot = bot_mod.deal_hole_cards(bot, hole_cards)
    {:reply, :ok, %State{state | bot: bot}}
  end

  # 轮到bot玩家行动
  def handle_call(
        {:todo_actions, username, _actions} = todo_actions,
        _from,
        %State{
          username: username,
          bot_mod: bot_mod,
          bot: bot
        } = state
      ) do
    log("处理行动 #{inspect(todo_actions)}")
    bot = bot_mod.update_todo_actions(bot, todo_actions)
    send(self(), :make_bot_decision)
    {:reply, :ok, %State{state | bot: bot}}
  end

  # 对手玩家行动
  def handle_call(
        {:todo_actions, username, actions},
        _from,
        %State{} = state
      ) do
    log("等待对手 #{username} 行动 #{inspect(actions)}")
    {:reply, :ok, state}
  end

  # 发公共牌
  def handle_call(
        {:deal_community_cards, street, community_cards},
        _from,
        %State{bot: bot, bot_mod: bot_mod} = state
      ) do
    log("bot收到新的公共牌 #{street} #{inspect(community_cards)}")
    bot = bot_mod.deal_community_cards(bot, street, community_cards)
    {:reply, :ok, %State{state | bot: bot}}
  end

  # 牌局结束
  def handle_call({:winner_result, winner, _, _}, _from, state) do
    log("bot收到牌局结果赢家为#{winner} 重新开始游戏")
    {:reply, :ok, state, {:continue, :will_start_game}}
  end

  def handle_call(request, _from, state) do
    warning_log("[UNKNOWN] handle_call #{inspect(request)}")
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_continue(:will_join_table, %State{username: username, table_id: table_id} = state) do
    Table.join_table(table_id, username)
    log("bot#{username} 加入桌子 #{table_id}")
    {:noreply, state, {:continue, :will_start_game}}
  end

  def handle_continue(:will_start_game, %State{username: username, table_id: table_id} = state) do
    log("bot#{username} 开始游戏 #{table_id}")
    Table.start_game(table_id, username)
    {:noreply, %State{state | bot: nil}}
  end

  @impl GenServer
  # 第一次收bets信息是盲注阶段, 此时初始化bot table
  def handle_cast(
        {:bets_info, bets_info},
        %State{username: username, bot_mod: bot_mod, bot: nil} = state
      ) do
    log("bot#{username}收到盲注下注信息 #{inspect(bets_info)}")
    bot = bot_mod.new(username, bets_info)
    {:noreply, %State{state | bot: bot}}
  end

  # 再收到bets信息就是后续持续双方下注了
  def handle_cast(
        {:bets_info, bets_info},
        %State{username: username, bot: bot, bot_mod: bot_mod} = state
      ) do
    log("bot#{username}收到双方下注信息 #{inspect(bets_info)}")
    bot = bot_mod.update_bets(bot, bets_info)
    {:noreply, %State{state | bot: bot}}
  end

  def handle_cast({:notify_players_info, players_info}, state) do
    log("#{state.username}收到玩家信息 #{inspect(players_info)}")
    {:noreply, state}
  end

  def handle_cast(msg, %State{} = state) do
    warning_log("[UNKNOWN] handle_cast #{inspect(msg)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:make_bot_decision, %State{bot: bot, bot_mod: bot_mod} = state) do
    action = bot_mod.make_decision(bot)
    log("BOT ACTION: #{inspect(action)}")
    Table.player_action_done(state.table_id, state.username, action)
    {:noreply, state}
  end

  defp log(msg) do
    Logger.info("#{inspect(self())} " <> msg, ansi_color: :light_yellow)
  end

  defp warning_log(msg) do
    Logger.warning("#{inspect(self())} " <> msg, ansi_color: :light_red)
  end
end
