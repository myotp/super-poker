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
defmodule SuperPoker.GameServer.HeadsupTableServer do
  use GenServer
  # alias SuperPoker.Core.Deck
  # alias SuperPoker.Core.Hand
  # alias SuperPoker.Core.Ranking
  alias SuperPoker.GameServer.TableManager
  alias SuperPoker.GameServer.TableConfig
  alias SuperPoker.GameServer.HeadsupTableState
  require Logger

  @moduledoc """
  具体每一个牌桌的GenServer进程
  """
  # ======================== 对外 API ================================
  def join_table(table_id, username) do
    GenServer.call(via_table_id(table_id), {:join_table, username})
  end

  def leave_table(table_id, username) do
    GenServer.call(via_table_id(table_id), {:leave_table, username})
  end

  def start_game(table_id, username) do
    GenServer.call(via_table_id(table_id), {:start_game, username})
  end

  def player_action_done(table_id, username, action) do
    GenServer.call(via_table_id(table_id), {:player_action_done, username, action})
  end

  defp via_table_id(table_id) do
    {:via, Registry, {SuperPoker.GameServer.TableRegistry, table_id}}
  end

  # ===================== 定义主体 %State{} 结构 =======================
  defmodule State do
    defstruct [
      # 注入可替换规则引擎
      :rules_mod,
      :rules,
      :rules_p2u,
      :rules_u2p,
      :table_state
    ]
  end

  # defmodule Player do
  #   defstruct [:pos, :username, :chips, :current_street_bet, :status]
  # end

  # ===================== OTP 回调部分 =================================
  def start_link(%{id: table_id} = args) do
    log("启动 单挑对局桌子 ID=#{table_id}")
    GenServer.start_link(__MODULE__, args, name: via_table_id(table_id))
  end

  @impl GenServer
  def init(
        %{
          id: table_id,
          max_players: max_players,
          sb: sb,
          bb: bb,
          buyin: buyin,
          rules: rules_mod
        } = args
      ) do
    table_state = HeadsupTableState.new(args)

    TableManager.register_table(%TableConfig{
      table_id: table_id,
      max_players: max_players,
      sb: sb,
      bb: bb,
      buyin: buyin
    })

    {:ok, %State{table_state: table_state, rules_mod: rules_mod}}
  end

  @impl GenServer
  def handle_call({:join_table, username}, _from, %State{table_state: table_state} = state) do
    case HeadsupTableState.join_table(table_state, username) do
      {:ok, updated_table_state} ->
        notify_players_info(updated_table_state)
        {:reply, :ok, %State{state | table_state: updated_table_state}}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:leave_table, username}, _from, %State{table_state: table_state} = state) do
    case HeadsupTableState.leave_table(table_state, username) do
      {:ok, chips_on_table, updated_table_state} ->
        notify_players_info(updated_table_state)
        {:reply, {:ok, chips_on_table}, %State{state | table_state: updated_table_state}}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:start_game, username}, _from, %State{table_state: table_state} = state) do
    case HeadsupTableState.player_start_game(table_state, username) do
      {:ok, updated_table_state} ->
        notify_players_info(updated_table_state)

        {:reply, :ok, %State{state | table_state: updated_table_state},
         {:continue, :maybe_table_start_game}}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(
        {:player_action_done, username, action},
        _from,
        %State{rules: rules, rules_mod: rules_mod, rules_u2p: u2p} = state
      ) do
    IO.puts("===>>>> [WIP] 收到玩家 #{username} 行动 #{inspect(action)}")
    rules = rules_mod.handle_action(rules, {:player, {u2p[username], action}})
    IO.inspect(rules, label: "最新下注之后的rules")
    state = %State{state | rules: rules}
    notify_all_players_bets_info(state)
    {:reply, :ok, state, {:continue, :do_next_action}}
  end

  @impl GenServer
  def handle_continue(
        :maybe_table_start_game,
        %State{table_state: table_state, rules_mod: rules_mod} = state
      ) do
    if HeadsupTableState.can_table_start_game?(table_state) do
      {rules_pos_chips, rules_p2u} =
        HeadsupTableState.generate_players_data_for_rules_engine(table_state)

      rules_u2p =
        rules_p2u
        |> Enum.map(fn {pos, username} -> {username, pos} end)
        |> Map.new()

      IO.inspect(rules_pos_chips, label: "===>>> Rules对应DATA")

      rules =
        rules_mod.new(
          rules_pos_chips,
          table_state.button_pos,
          {table_state.sb_amount, table_state.bb_amount}
        )

      updated_table_state = HeadsupTableState.table_start_game!(table_state)
      IO.inspect(updated_table_state, label: "更新过后的TableState")

      state = %State{
        state
        | table_state: updated_table_state,
          rules: rules,
          rules_p2u: rules_p2u,
          rules_u2p: rules_u2p
      }

      {:noreply, state, {:continue, :do_next_action}}
    else
      {:noreply, state}
    end
  end

  # FIXME: 这里事件之后, 可以用通用的下注信息来处理盲注下注, 故此步骤可以省略
  def handle_continue(
        :do_next_action,
        %State{
          rules: %{next_action: {:table, {:notify_blind_bet, _blinds}}}
        } =
          state
      ) do
    {:noreply, state, {:continue, :notify_blind_bet_done}}
  end

  def handle_continue(
        :notify_blind_bet_done,
        %State{
          rules: rules,
          rules_mod: rules_mod
        } =
          state
      ) do
    rules = rules_mod.handle_action(rules, {:table, :notify_blind_bet_done})
    IO.inspect(rules, label: "============ 通知完盲注的RULES")
    updated_state = %State{state | rules: rules}
    notify_all_players_bets_info(updated_state)
    {:noreply, %State{state | rules: rules}, {:continue, :deal_hole_cards}}
  end

  def handle_continue(:deal_hole_cards, %State{table_state: table_state} = state) do
    updated_table_state = HeadsupTableState.deal_hole_cards!(table_state)
    hole_cards_info = HeadsupTableState.hole_cards_info!(updated_table_state)

    Enum.each(hole_cards_info, fn {username, hole_cards} ->
      player_mod().deal_hole_cards(username, hole_cards)
    end)

    IO.inspect(updated_table_state, label: "发完2张牌之后的state")
    {:noreply, %State{state | table_state: updated_table_state}, {:continue, :do_next_action}}
  end

  # 下一步玩家动作
  def handle_continue(
        :do_next_action,
        %State{
          table_state: table_state,
          rules: %{next_action: {:player, {pos, actions}}},
          rules_p2u: usernames
        } = state
      ) do
    all_players = HeadsupTableState.all_players(table_state)
    player_mod().notify_player_action(all_players, usernames[pos], actions)
    {:noreply, state}
  end

  def handle_continue(
        :do_next_action,
        %State{table_state: table_state, rules: %{next_action: {:table, {:deal, street}}}} = state
      ) do
    log("牌桌即将发牌#{street}")
    {cards, updated_table_state} = HeadsupTableState.deal_community_cards!(table_state, street)
    all_players = HeadsupTableState.all_players(table_state)
    player_mod().deal_community_cards(all_players, street, cards)

    {:noreply, %State{state | table_state: updated_table_state},
     {:continue, {:deal_done, street}}}
  end

  def handle_continue({:deal_done, street}, %State{rules: rules, rules_mod: rules_mod} = state) do
    rules = rules_mod.handle_action(rules, {:table, {:done, street}})
    updated_state = %State{state | rules: rules}
    # 发完牌之后, 清空之前一轮下注, 更新pot, 通知全体玩家
    notify_all_players_bets_info(updated_state)
    {:noreply, updated_state, {:continue, :do_next_action}}
  end

  # TODO TODO TODO

  # 到最后摊牌阶段，rules无从知道谁大谁小，只返回pot与每个人最后的剩余筹码，服务器决定赢者拿走多少
  # def handle_continue(
  #       :do_next_action,
  #       %State{
  #         rules: %{next_action: {:table, {:show_hands, {pot_amount, chips_left_by_rules_pos}}}},
  #         table_state: table_state
  #       } = state
  #     ) do
  #   username0 = pos_to_username(state, 0)
  #   username1 = pos_to_username(state, 1)

  #   case decide_winner_result(state) do
  #     {nil, type, cards1, cards2} ->
  #       half_pot = div(pot, 2)

  #       players_chips =
  #         chips
  #         |> Map.update!(0, fn current -> current + half_pot end)
  #         |> Map.update!(1, fn current -> current + half_pot end)

  #       hole_cards = %{username0 => player_cards[0], username1 => player_cards[1]}
  #       chips = %{username0 => players_chips[0], username1 => players_chips[1]}

  #       player.notify_winner_result(
  #         all_players(state),
  #         nil,
  #         chips,
  #         {type, hole_cards, cards1, cards2}
  #       )

  #       state = put_in(state.p0.chips, players_chips[0])
  #       state = put_in(state.p1.chips, players_chips[1])
  #       state = put_in(state.p0.status, :JOINED)
  #       state = put_in(state.p1.status, :JOINED)
  #       {:noreply, %State{state | table_status: :WAITING}}

  #     {winner_pos, type, win5, lose5} ->
  #       username = pos_to_username(state, winner_pos)
  #       players_chips = Map.update!(chips, winner_pos, fn current -> current + pot end)
  #       chips = %{username0 => players_chips[0], username1 => players_chips[1]}

  #       hole_cards = %{username0 => player_cards[0], username1 => player_cards[1]}

  #       player.notify_winner_result(
  #         all_players(state),
  #         username,
  #         chips,
  #         {type, hole_cards, win5, lose5}
  #       )

  #       state = put_in(state.p0.chips, players_chips[0])
  #       state = put_in(state.p1.chips, players_chips[1])
  #       state = put_in(state.p0.status, :JOINED)
  #       state = put_in(state.p1.status, :JOINED)
  #       {:noreply, %State{state | table_status: :WAITING}}
  #   end
  # end

  def handle_continue(
        :do_next_action,
        %State{rules: %{next_action: action}} = state
      ) do
    IO.inspect(action, label: "TODO ACTION")
    {:noreply, state}
  end

  # # 一方投降，不用比牌，rules已经算好pot给谁，最终每个人多少了
  # def handle_continue(
  #       :do_next_action,
  #       %State{table: %{next_action: {:winner, pos, players_chips}}, player_mod: player} = state
  #     ) do
  #   username = pos_to_username(state, pos)
  #   user0 = pos_to_username(state, 0)
  #   user1 = pos_to_username(state, 1)
  #   chips_by_username = %{user0 => players_chips[0], user1 => players_chips[1]}
  #   IO.inspect(player, label: "具体player模块")
  #   player.notify_winner_result(all_players(state), username, chips_by_username, nil)
  #   state = put_in(state.p0.chips, players_chips[0])
  #   state = put_in(state.p1.chips, players_chips[1])
  #   # TODO: 更新筹码信息发送给客户端
  #   state = put_in(state.p0.status, :JOINED)
  #   state = put_in(state.p1.status, :JOINED)
  #   {:noreply, %State{state | table_status: :WAITING}}
  # end

  # # 牌桌操作事件顺序

  # @impl GenServer
  # def handle_cast(:debug_state, state) do
  #   IO.inspect(state, label: "牌桌状态")
  #   {:noreply, state}
  # end

  # =================== 基于%State{} 的大操作函数 =====
  defp notify_players_info(table_state) do
    all_players = HeadsupTableState.all_players(table_state)
    players_info = HeadsupTableState.players_info(table_state)
    IO.inspect(all_players, label: "桌子通知所有玩家")
    player_mod().notify_players_info(all_players, players_info)
  end

  def notify_all_players_bets_info(%State{table_state: table_state, rules: rules, rules_p2u: p2u}) do
    bets_info = generate_bets_info(rules, p2u)
    all_players = HeadsupTableState.all_players(table_state)
    player_mod().notify_bets_info(all_players, bets_info)
  end

  # defp reset_cards(state) do
  #   %State{
  #     state
  #     | deck: Deck.seq_deck52() |> Deck.shuffle() |> Deck.top_n_cards(9),
  #       player_cards: %{},
  #       community_cards: []
  #   }
  # end

  # defp decide_winner_result(%State{community_cards: community_cards} = state) do
  #   5 = Enum.count(community_cards)

  #   cards0 = state.player_cards[0]
  #   cards1 = state.player_cards[1]

  #   rank0 = Ranking.run(cards0 ++ community_cards)
  #   rank1 = Ranking.run(cards1 ++ community_cards)

  #   case Hand.compare(cards0, cards1, community_cards) do
  #     :win ->
  #       {0, rank0.type, rank0.best_hand, rank1.best_hand}

  #     :lose ->
  #       {1, rank1.type, rank1.best_hand, rank0.best_hand}

  #     :tie ->
  #       {nil, rank0.type, rank0.best_hand, rank1.best_hand}
  #   end
  # end

  # defp take_cards(state, :flop) do
  #   do_deal_community_cards(state, 3)
  # end

  # defp take_cards(state, :turn) do
  #   do_deal_community_cards(state, 1)
  # end

  # defp take_cards(state, :river) do
  #   do_deal_community_cards(state, 1)
  # end

  # defp do_deal_community_cards(%State{deck: deck, community_cards: community_cards} = state, n) do
  #   {cards, rest} = Enum.split(deck, n)
  #   {cards, %State{state | deck: rest, community_cards: community_cards ++ cards}}
  # end

  # defp all_players(state) do
  #   [state.p0.username, state.p1.username]
  # end

  # defp pos_to_username(state, 0) do
  #   state.p0.username
  # end

  # defp pos_to_username(state, 1) do
  #   state.p1.username
  # end

  # defp username_to_pos(state, username) do
  #   case {state.p0.username, state.p1.username} do
  #     {^username, _} ->
  #       0

  #     {_, ^username} ->
  #       1
  #   end
  # end

  # defp generate_players_data_for_rules_engine(state) do
  #   %{0 => state.p0.chips, 1 => state.p1.chips}
  # end

  # 先保持原先的数据结构不变
  # %{
  #   :pot => 0,
  #   "anna" => %{chips_left: 490, current_street_bet: 10},
  #   "bob" => %{chips_left: 495, current_street_bet: 5}
  # }
  def generate_bets_info(%{pot: pot, players: players}, pos_usernames) do
    players_bets_info =
      Enum.map(players, fn {rules_pos, p} ->
        {pos_usernames[rules_pos],
         %{chips_left: p.chips, current_street_bet: p.current_street_bet}}
      end)

    Map.new([{:pot, pot} | players_bets_info])
  end

  defp log(msg) do
    Logger.info("#{inspect(self())}" <> msg, ansi_color: :cyan)
  end

  defp player_mod() do
    Application.get_env(:super_poker, :player_mod, SuperPoker.PlayerNotify.PlayerRequestSender)
  end
end
