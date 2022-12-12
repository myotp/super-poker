defmodule SuperPoker.Core.Rules1v1 do
  @moduledoc """

  1v1单挑对战局规则引擎

  具体一局牌局的整体游戏规则引导部分，只负责引导牌局流程，不涉及具体牌型大小比较等

  设计方面，坚持分层考虑，这里所在层只考虑单一一局牌的情况，接收的参数就只有真正加入的玩家，比如一个桌子座位编号1..9
  但是其中只有部分比如2,5,6,7有坐人，传入这里的时候，都统一整理成0..3
  这里只从逻辑角度处理一局牌，至于从桌子层面2567映射到0123由上层负责
  采用Design Elixir OTP的大状态法来方便实现复杂德州扑克过程的状态变迁演化，大大优于Sudoku当时的实战效果

  fisrt_action_pos为本回合起始，同时也就是终止位
  current_action_pos总是指向下一个，不管是否active，后边decide的时候，再去行动
  这样，在decide_next_action之前，总是可以用current_action_pos来判断当前回合是否结束

  Street: preflop -> flop -> turn -> river

  因为之前直接启动最完整的Rules最终就没做完，2人对战简化很多，比如一个fold了，就结束了
  或者allin了，就直接allin了，不怕遇到有人不够allin，另开一个局的效果
  """

  @user_default_actions [:raise, :allin, :fold]

  defmodule State do
    @moduledoc """
    这里是Rules内部State的类型定义部分，这里文档方便自己查看

    名词规则定义参考 https://www.pokernews.com/poker-rules/texas-holdem.htm
    """

    defstruct [
      # 当前stage状态preflop, flop, turn, river
      :current_street,

      # 当前牌局所有玩家大map汇总
      :players,

      # 累计池中筹码总数
      :pot,
      :current_street_bet,
      :current_call_amount,

      # 起手总共玩家数量
      :num_players,
      :sb_amount,
      :bb_amount,

      # 围绕桌子上位置一些定义
      :button_pos,
      :sb_pos,
      :bb_pos,

      # 第一行动位置，也就是结束位置，回合中，可以随着raise不断变化
      :start_action_pos,
      # 下一行动位置
      :current_action_pos,
      # 状态机决定下一步的操作
      :next_action
    ]
  end

  defmodule Player do
    defstruct [
      # 玩家逻辑序号0-9
      :n,
      # 玩家参与本牌局的实时剩余可下注筹码数
      :chips,
      # 当前回合已下注累计，比如sb，bb或者被raise之前所下注等
      :current_street_bet,
      # active | fold | allin
      status: :active
    ]
  end

  def new(players_data, button_pos, {sb_amount, bb_amount}) do
    total = Enum.count(players_data)

    %State{
      sb_amount: sb_amount,
      bb_amount: bb_amount,
      button_pos: button_pos,
      num_players: total,
      pot: 0,
      current_street: :preflop,
      current_street_bet: 0,
      players: players_from_tuple_list(players_data)
    }
    |> set_sb_and_bb_pos()
    |> do_preflop()
  end

  def handle_action(state, {:player, pos, action}) do
    handle_player_action(state, pos, action)
  end

  def handle_action(state, {:table, {:deal, street}}) do
    state
    |> set_current_street(street)
    |> reset_current_street_bet()
    |> reset_street_action_pos()
    |> decide_next_player_action()
  end

  defp handle_player_action(state, pos, :check) do
    handle_player_action(state, pos, {:call, 0})
  end

  defp handle_player_action(state, pos, {:call, amount}) do
    state
    |> make_player_bet(pos, amount)
    |> decide_next_action()
  end

  defp decide_next_action(%State{start_action_pos: start_action_pos} = state) do
    case next_table_pos(state.num_players, state.current_action_pos) do
      ^start_action_pos ->
        state
        |> finish_current_street_bet()
        |> decide_next_table_action()

      next_player_pos ->
        state = %State{state | current_action_pos: next_player_pos}
        decide_next_player_action(state)
    end
  end

  defp decide_next_table_action(%State{current_street: current_street} = state) do
    case current_street do
      :preflop ->
        %State{state | next_action: {:table, {:deal, :flop}}}

      :flop ->
        %State{state | next_action: {:table, {:deal, :turn}}}

      :turn ->
        %State{state | next_action: {:table, {:deal, :river}}}

      :river ->
        %State{
          state
          | next_action: {:table, {:show_hands, show_hands_result(state)}}
        }
    end
  end

  defp show_hands_result(state) do
    {[0, 1], state.pot, players_chips(state)}
  end

  defp players_chips(%State{players: players}) do
    for {n, p} <- players do
      {n, p.chips}
    end
    |> Enum.sort()
  end

  defp decide_next_player_action(%State{current_action_pos: current_action_pos} = state) do
    player = get_player_at_pos(state, current_action_pos)
    player_already_bet = player.current_street_bet
    action = player_actions(player_already_bet, state.current_call_amount)
    %State{state | next_action: {:player, current_action_pos, [action | @user_default_actions]}}
  end

  defp player_actions(player_bet, amount_to_call) when player_bet == amount_to_call do
    :check
  end

  # FIXME: 假设玩家筹码总是满足的情况下
  defp player_actions(player_already_bet, amount_to_call) do
    {:call, amount_to_call - player_already_bet}
  end

  defp set_current_street(state, :flop), do: %State{state | current_street: :flop}
  defp set_current_street(state, :turn), do: %State{state | current_street: :turn}
  defp set_current_street(state, :river), do: %State{state | current_street: :river}

  defp finish_current_street_bet(%State{current_street_bet: current_street_bet, pot: pot} = state) do
    %State{state | pot: pot + current_street_bet, current_street_bet: 0}
  end

  defp next_table_pos(total, pos) do
    Integer.mod(pos + 1, total)
  end

  defp get_player_at_pos(state, pos) do
    state.players[pos]
  end

  defp set_sb_and_bb_pos(%State{button_pos: button_pos, num_players: 2} = state) do
    %State{state | sb_pos: button_pos, bb_pos: next_pos(state.num_players, button_pos)}
  end

  defp players_from_tuple_list(players_data) do
    Enum.reduce(players_data, Map.new(), fn {n, chips}, acc ->
      Map.put(acc, n, %Player{n: n, chips: chips})
    end)
  end

  # 处理每一条街
  defp do_preflop(state) do
    state
    |> reset_current_street_bet()
    |> reset_players_current_street_bet()
    |> force_bet_sb_and_bb()
    |> reset_street_action_pos()
    |> decide_next_player_action()
  end

  defp reset_current_street_bet(%State{} = state) do
    %State{state | current_street_bet: 0}
  end

  defp reset_players_current_street_bet(%State{players: players} = state) do
    new_players =
      players
      |> Enum.map(fn {n, %Player{} = player} -> {n, %{player | current_street_bet: 0}} end)
      |> Enum.into(%{})

    %State{state | players: new_players}
  end

  # 二人单挑只有第一次行动从button（小盲）开始
  defp reset_street_action_pos(
         %State{num_players: 2, current_street: :preflop, button_pos: button_pos} = state
       ) do
    %State{state | start_action_pos: button_pos, current_action_pos: button_pos}
  end

  # 之后的几条街都是大盲（非button位）开始
  defp reset_street_action_pos(%State{num_players: 2, button_pos: button_pos} = state) do
    %State{
      state
      | start_action_pos: next_pos(2, button_pos),
        current_action_pos: next_pos(2, button_pos)
    }
  end

  defp next_pos(total, pos, n \\ 1)
  defp next_pos(total, pos, 1), do: Integer.mod(pos + 1, total)

  defp force_bet_sb_and_bb(
         %State{sb_amount: sb_amount, bb_amount: bb_amount, sb_pos: sb_pos, bb_pos: bb_pos} =
           state
       ) do
    state =
      state
      |> make_player_bet(sb_pos, sb_amount)
      |> make_player_bet(bb_pos, bb_amount)

    %State{state | current_call_amount: bb_amount}
  end

  defp make_player_bet(state, pos, amount) do
    state = update_in(state.players[pos], &do_player_bet(&1, amount))
    %State{state | current_street_bet: state.current_street_bet + amount}
  end

  defp do_player_bet(%Player{chips: chips, current_street_bet: already_bet} = player, amount)
       when chips >= amount do
    %Player{player | chips: chips - amount, current_street_bet: already_bet + amount}
  end
end
