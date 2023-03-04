# TODO: 这里，先简单实现单挑桌，很多硬写的p0 p1后续都需要通用处理化
# TODO: 不过，好处是想到反正基于名字，完全不需要客户端，可以先独立完成服务器并测试
# TODO: 后续，结合Testing Elixir看看OTP部分如何测试，以及Design Elixir OTP也有提到OTP测试
# TODO: 这里的table_server尽量不去处理信息，比如中间过程玩家筹码量的，完全交给rules控制就完事了
# 筹码的控制，table_server不去管，而是rules去控制，table_server只负责转发给具体player_server
# 具体player_server掌握自己持有的有效筹码量，并且，应该跟rules持有的是一致的

# TODO 设计改进重构
# 这里，最开始，硬写的p0, p1，然后跟玩家部分交互的时候，用的username基本是必须的，因为需要对应进程
# 而Rules当中的0，1，2是一种抽象，比如最终桌子8人桌，只坐了三个人的话，依然抽象成0，1，2的表示
# 后续再去考虑每个玩家所坐的位置，眼下就两个人的话，相对比较容易，不过基本原则要定好
# 也就是table_server与玩家交互，全部使用username，便于进程查找调用
# 反过来也一样，玩家最终player_server与table_server交互的时候，也是用的username
# 最终翻译成Rules所需的012整理化表示，由table_server去完成
defmodule SuperPoker.Multiplayer.HeadsupTableServer do
  use GenServer
  alias SuperPoker.Multiplayer.Player, as: PlayerAPI
  alias SuperPoker.Core.Deck
  alias SuperPoker.Core.Hand
  alias SuperPoker.Core.Ranking
  require Logger

  @moduledoc """
  具体每一个牌桌的GenServer进程
  """
  # ======================== 对外 API ================================
  def join_table(table_id, username) do
    GenServer.call(via_table_id(table_id), {:join_table, username})
  end

  def start_game(table_id, username) do
    GenServer.call(via_table_id(table_id), {:start_game, username})
  end

  def player_action_done(table_id, username, action) do
    GenServer.call(via_table_id(table_id), {:player_action_done, username, action})
  end

  # for testing
  def get_state(table_id) do
    GenServer.call(via_table_id(table_id), :get_state)
  end

  def debug_state(table_id) do
    GenServer.cast(via_table_id(table_id), :debug_state)
  end

  defp via_table_id(table_id) do
    {:via, Registry, {SuperPoker.Multiplayer.TableRegistry, table_id}}
  end

  # ===================== 定义主体 %State{} 结构 =======================
  defmodule State do
    defstruct [
      # 静态牌桌本身信息
      :max_players,
      :sb_amount,
      :bb_amount,
      :buyin,
      :rules_mod,
      # 动态牌桌信息
      table: nil,
      table_status: :WAITING,
      # 动态牌信息
      deck: [],
      community_cards: [],
      player_cards: %{},
      # 动态玩家信息
      p0: nil,
      p1: nil,
      button_pos: 0
    ]
  end

  defmodule Player do
    defstruct [:pos, :username, :chips, :status]
  end

  # ===================== OTP 回调部分 =================================
  def start_link(%{id: table_id} = args) do
    log("启动 单挑对局桌子 ID=#{table_id}")
    GenServer.start_link(__MODULE__, args, name: via_table_id(table_id))
  end

  @impl GenServer
  def init(%{
        max_players: max_players,
        sb: sb,
        bb: bb,
        buyin: buyin,
        rules: mod
      }) do
    state = %State{
      max_players: max_players,
      sb_amount: sb,
      bb_amount: bb,
      buyin: buyin,
      rules_mod: mod
    }

    log("启动牌桌进程 #{inspect(state)}")
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:join_table, username}, _from, state) do
    case {state.p0, state.p1} do
      {%Player{}, %Player{}} ->
        {:reply, {:error, :table_full}, state}

      {nil, _} ->
        p0 = %Player{pos: 0, username: username, chips: state.buyin, status: :JOINED}
        {:reply, :ok, %State{state | p0: p0}}

      {_, nil} ->
        p1 = %Player{pos: 1, username: username, chips: state.buyin, status: :JOINED}
        {:reply, :ok, %State{state | p1: p1}}
    end
  end

  def handle_call({:start_game, username}, _from, state) do
    state =
      case {state.p0.username, state.p1.username} do
        {^username, _} ->
          put_in(state.p0.status, :READY)

        {_, ^username} ->
          put_in(state.p1.status, :READY)
      end

    {:reply, :ok, state, {:continue, :maybe_start_game}}
  end

  def handle_call(
        {:player_action_done, username, action},
        _from,
        %State{table: table, rules_mod: mod} = state
      ) do
    IO.puts("收到玩家 #{username} 行动 #{inspect(action)}")
    table = mod.handle_action(table, {:player, {username_to_pos(state, username), action}})
    {:reply, :ok, %State{state | table: table}, {:continue, :do_next_action}}
  end

  # 测试用
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_continue(:maybe_start_game, state) do
    if all_players_ready?(state) do
      {:noreply, start_new_game(state), {:continue, :do_next_action}}
    else
      {:noreply, state}
    end
  end

  def handle_continue(
        :do_next_action,
        %State{table: %{next_action: {:table, {:notify_blind_bet, blinds}}}} = state
      ) do
    blinds =
      blinds
      |> Enum.map(fn {pos, amount} -> {pos_to_username(state, pos), amount} end)

    IO.inspect(blinds)
    PlayerAPI.notify_blind_bet(all_players(state), blinds)
    {:noreply, state, {:continue, :notify_blind_bet_done}}
  end

  # 需要player操作的事件，就只是简单转发通知即可
  def handle_continue(
        :do_next_action,
        %State{table: %{next_action: {:player, {pos, actions}}}} = state
      ) do
    username = pos_to_username(state, pos)
    PlayerAPI.notify_player_action(all_players(state), username, actions)
    {:noreply, state}
  end

  def handle_continue(
        :do_next_action,
        %State{table: %{next_action: {:table, {:deal, street}}}} = state
      ) do
    IO.puts("牌桌即将发牌#{street}")
    {cards, new_state} = take_cards(state, street)
    PlayerAPI.notify_deal_cards(all_players(new_state), street, cards)
    {:noreply, new_state, {:continue, {:deal_done, street}}}
  end

  # 到最后摊牌阶段，rules无从知道谁大谁小，只返回pot与每个人最后的剩余筹码，服务器决定赢者拿走多少
  def handle_continue(
        :do_next_action,
        %State{table: %{next_action: {:table, {:show_hands, {pot, chips}}}}} = state
      ) do
    {winner_pos, type, win5, lose5} = decide_winner_pos(state)
    username = pos_to_username(state, winner_pos)
    players_chips = Map.update!(chips, winner_pos, fn current -> current + pot end)

    PlayerAPI.notify_winner_result(
      all_players(state),
      username,
      players_chips,
      {type, win5, lose5}
    )

    state = put_in(state.p0.chips, players_chips[0])
    state = put_in(state.p1.chips, players_chips[1])
    state = put_in(state.p0.status, :JOINED)
    state = put_in(state.p1.status, :JOINED)
    {:noreply, %State{state | table_status: :WAITING}}
  end

  # 一方投降，不用比牌，rules已经算好pot给谁，最终每个人多少了
  def handle_continue(
        :do_next_action,
        %State{table: %{next_action: {:winner, pos, players_chips}}} = state
      ) do
    username = pos_to_username(state, pos)
    PlayerAPI.notify_winner_result(all_players(state), username, players_chips)
    state = put_in(state.p0.chips, players_chips[0])
    state = put_in(state.p1.chips, players_chips[1])
    state = put_in(state.p0.status, :JOINED)
    state = put_in(state.p1.status, :JOINED)
    {:noreply, %State{state | table_status: :WAITING}}
  end

  def handle_continue(:do_next_action, %State{table: %{next_action: action}} = state) do
    IO.inspect(action, label: "TODO处理接下来事件")
    {:noreply, state}
  end

  # 牌桌操作事件顺序
  def handle_continue(:notify_blind_bet_done, %State{table: table, rules_mod: mod} = state) do
    table = mod.handle_action(table, {:table, :notify_blind_bet_done})
    {:noreply, %State{state | table: table}, {:continue, :deal_hole_cards}}
  end

  def handle_continue(:deal_hole_cards, %State{deck: deck} = state) do
    [c1, c2, c3, c4 | rest] = deck
    p0 = pos_to_username(state, 0)
    p1 = pos_to_username(state, 1)
    cards0 = [c1, c2]
    cards1 = [c3, c4]
    player_cards = %{0 => cards0, 1 => cards1}
    PlayerAPI.deal_hole_cards(p0, cards0)
    PlayerAPI.deal_hole_cards(p1, cards1)

    {:noreply, %State{state | deck: rest, player_cards: player_cards, community_cards: []},
     {:continue, :do_next_action}}
  end

  def handle_continue({:deal_done, street}, %State{table: table, rules_mod: mod} = state) do
    IO.inspect(street, label: "完成发牌")
    table = mod.handle_action(table, {:table, {:done, street}})
    {:noreply, %State{state | table: table}, {:continue, :do_next_action}}
  end

  @impl GenServer
  def handle_cast(:debug_state, state) do
    log("牌桌状态 #{inspect(state)}")
    {:noreply, state}
  end

  # =================== 基于%State{} 的大操作函数 =====
  defp start_new_game(%State{rules_mod: rules_mod, sb_amount: sb, bb_amount: bb} = state) do
    players_data = generate_players_data_for_rules_engine(state)
    table = rules_mod.new(players_data, state.button_pos, {sb, bb})
    state = reset_cards(state)
    %State{state | table_status: :RUNNING, table: table}
  end

  defp reset_cards(state) do
    %State{
      state
      | deck: Deck.seq_deck52() |> Deck.shuffle() |> Deck.top_n_cards(9),
        player_cards: %{},
        community_cards: []
    }
  end

  defp decide_winner_pos(%State{community_cards: community_cards} = state) do
    5 = Enum.count(community_cards)

    cards0 = state.player_cards[0]
    cards1 = state.player_cards[1]

    rank0 = Ranking.run(cards0 ++ community_cards)
    rank1 = Ranking.run(cards1 ++ community_cards)

    case Hand.compare(cards0, cards1, community_cards) do
      :win ->
        {0, rank0.type, rank0.best_hand, rank1.best_hand}

      :lose ->
        {1, rank1.type, rank1.best_hand, rank0.best_hand}
    end
  end

  defp take_cards(state, :flop) do
    do_deal_community_cards(state, 3)
  end

  defp take_cards(state, :turn) do
    do_deal_community_cards(state, 1)
  end

  defp take_cards(state, :river) do
    do_deal_community_cards(state, 1)
  end

  defp do_deal_community_cards(%State{deck: deck, community_cards: community_cards} = state, n) do
    {cards, rest} = Enum.split(deck, n)
    {cards, %State{state | deck: rest, community_cards: community_cards ++ cards}}
  end

  defp all_players(state) do
    [state.p0.username, state.p1.username]
  end

  defp pos_to_username(state, 0) do
    state.p0.username
  end

  defp pos_to_username(state, 1) do
    state.p1.username
  end

  defp username_to_pos(state, username) do
    case {state.p0.username, state.p1.username} do
      {^username, _} ->
        0

      {_, ^username} ->
        1
    end
  end

  defp all_players_ready?(state) do
    case {state.p0.status, state.p1.status} do
      {:READY, :READY} -> true
      _ -> false
    end
  end

  defp generate_players_data_for_rules_engine(state) do
    %{0 => state.p0.chips, 1 => state.p1.chips}
  end

  # =================== 其它 ======================
  defp log(msg) do
    Logger.info("#{inspect(self())}" <> msg, ansi_color: :cyan)
  end
end
