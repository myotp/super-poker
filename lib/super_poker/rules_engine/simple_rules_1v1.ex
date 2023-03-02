defmodule SuperPoker.RulesEngine.SimpleRules1v1 do
  @moduledoc """

  1v1单挑对战局规则引擎

  参考原来的rules1v1实现，但是现在做一些修改：
  - 尽量简化到不做错误检查
  - 简化到特定只能二人对战，从而简化内部表达
  - 尽量做到完整包含，对外OTP服务器连fold都不需要知道是可选操作

  具体一局牌局的整体游戏规则引导部分，只负责引导牌局流程，不涉及具体牌型大小比较等

  采用Design Elixir OTP的大状态法来方便实现复杂德州扑克过程的状态变迁演化，大大优于Sudoku当时的实战效果
  """

  defmodule Player do
    @moduledoc """
    牌桌对局中，玩家抽象

    不再包含序号N，因为固定只有两个玩家了现在
    不再包含status，因为两个玩家，一方fold了，则马上结束了就
    现在所含内容不多，但尽量保留这一层抽象
    """
    defstruct [
      # 保留回来玩家pos位置，相当于原来的seq N，因为之前的实现，大量用到pos，相对统一，同时易于后续扩展
      :pos,
      # 玩家参与本牌局的实时剩余可下注筹码数
      :chips,
      # 当前回合已下注累计，比如sb，bb或者被raise之前所下注等
      :current_street_bet
    ]
  end

  defmodule Table do
    @moduledoc """
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
      :sb_amount,
      :bb_amount,

      # 围绕桌子上位置一些定义
      :button_pos,
      :sb_pos,
      :bb_pos,
      :num_players,

      # 第一行动位置，也就是结束位置，回合中，可以随着raise不断变化
      :end_player_pos,

      # 下一行动玩家位置
      :next_player_pos,

      # 状态机决定下一步的操作
      :next_action
    ]
  end

  # ============== 主要处理逻辑 =================
  def new(players_data, button_pos, {sb_amount, bb_amount}) do
    total = Enum.count(players_data)

    %Table{
      sb_amount: sb_amount,
      bb_amount: bb_amount,
      button_pos: button_pos,
      num_players: total,
      pot: 0,
      current_street: :preflop,
      current_street_bet: 0,
      players: from_players_input_data(players_data)
    }
    |> set_sb_and_bb_pos_for_only_two_players_game()
    |> decide_next_action()
  end

  # ============ 主要的基于状态机的决定当下操作 ============
  # 当pot为空, 且当前轮下注为0的时候，处于游戏最初状态，需要大小盲下注，这里也产生事件，好让游戏服务器通知各个玩家大小盲下注
  defp decide_next_action(
         %Table{
           pot: 0,
           current_street_bet: 0,
           sb_amount: sb_amount,
           bb_amount: bb_amount,
           sb_pos: sb_pos,
           bb_pos: bb_pos
         } = table
       ) do
    # 设计小改进，原先使用list，后来测试意识到%{}更好比较
    action = {:table, {:notify_blind_bet, %{sb_pos => sb_amount, bb_pos => bb_amount}}}
    %{table | next_action: action}
  end

  # 结束玩家为nil，表示前边尚未有任何玩家行动过
  defp decide_next_action(%Table{end_player_pos: nil} = table) do
    decide_next_player_action(table)
  end

  # 结束玩家不为下一个玩家，表示前边玩家有行动，现在轮到新玩家操作
  defp decide_next_action(%Table{end_player_pos: end_pos, next_player_pos: next_pos} = table)
       when end_pos != next_pos do
    decide_next_player_action(table)
  end

  # 下一个玩家即回到第一行动玩家位置，本回合下注阶段结束
  defp decide_next_action(%Table{end_player_pos: end_pos, next_player_pos: next_pos} = table)
       when end_pos == next_pos do
    decide_next_table_action(table)
  end

  defp decide_next_table_action(%Table{current_street: current_street} = table) do
    case current_street do
      :preflop ->
        %Table{table | next_action: {:table, {:deal, :flop}}}

      :flop ->
        %Table{table | next_action: {:table, {:deal, :turn}}}

      :turn ->
        %Table{table | next_action: {:table, {:deal, :river}}}

      :river ->
        %Table{table | next_action: {:table, {:show_hands, :todo}}}
    end
  end

  defp decide_next_player_action(%Table{next_player_pos: next_player_pos} = table) do
    player = get_player_at_pos(table, next_player_pos)
    player_already_bet = player.current_street_bet
    actions = player_actions(player_already_bet, table.current_call_amount)
    %Table{table | next_action: {:player, {next_player_pos, actions}}}
  end

  # 玩家已经下注满足当前call数量,开局大盲适用,或者首位行动玩家, 这里简化版对战规则刻意做了几点简化
  # 1. 不考虑玩家筹码不足的情况
  # 2. 不考虑复杂下注规则，比如限制倍数
  # 3. raise任意数量，并且假设是在满足call的之后的数量
  # 4. 假设服务器是个无知服务器，所以fold也这里显式返回
  defp player_actions(player_already_bet, current_call_amount)
       when player_already_bet == current_call_amount do
    [:fold, :check, :raise]
  end

  # 玩家已经下注未满足call数量，别人领叫，或者自己bet被raise的情况下
  defp player_actions(player_already_bet, current_call_amount) do
    amount_to_call = current_call_amount - player_already_bet
    [:fold, {:call, amount_to_call}, :raise]
  end

  # ============ 处理外部事件之后的规则推进 ===========
  def handle_action(table, {:table, :notify_blind_bet_done}) do
    table
    |> reset_current_street_bet_info()
    |> force_bet_sb_and_bb()
    |> reset_street_action_pos()
    |> decide_next_action()
  end

  # 玩家fold情况
  def handle_action(table, {:player, {player_pos, :fold}}) do
    winner_pos =
      case player_pos do
        0 -> 1
        1 -> 0
      end

    winner_chips = table.players[winner_pos].chips + table.pot + table.current_street_bet

    %Table{
      table
      | next_action:
          {:winner, winner_pos,
           %{player_pos => table.players[player_pos].chips, winner_pos => winner_chips}}
    }
  end

  # 玩家call平跟
  def handle_action(table, {:player, {player_pos, :call}}) do
    amount_to_call = player_amount_to_call(table, player_pos)

    table
    |> make_player_bet(player_pos, amount_to_call)
    |> maybe_set_end_player_pos()
    |> move_next_action_player_pos()
    |> decide_next_action()
  end

  # 玩家raise加注情况
  def handle_action(table, {:player, {player_pos, {:raise, x}}}) do
    amount_to_call = player_amount_to_call(table, player_pos)
    total_amount = amount_to_call + x

    table
    |> make_player_bet(player_pos, total_amount)
    |> maybe_set_end_player_pos(true)
    |> move_next_action_player_pos()
    |> decide_next_action()
  end

  # ============ 针对 %Table{} 大状态汇总的迭代处理函数 ===========
  # 只有两个玩家的时候，约定sb为button位置
  defp set_sb_and_bb_pos_for_only_two_players_game(
         %Table{button_pos: button_pos, num_players: 2} = table
       ) do
    %Table{table | sb_pos: button_pos, bb_pos: next_pos(2, button_pos)}
  end

  defp reset_current_street_bet_info(%Table{players: players} = table) do
    new_players =
      players
      |> Enum.map(fn {n, %Player{} = player} -> {n, %{player | current_street_bet: 0}} end)
      |> Enum.into(%{})

    %Table{table | current_street_bet: 0, current_call_amount: 0, players: new_players}
  end

  # 如果之前没有玩家行动过，则设置，或者加注情况下，设置
  defp maybe_set_end_player_pos(table, force \\ false)

  # 最普通情况，尚未有玩家行动过，第一玩家即为终止位置
  defp maybe_set_end_player_pos(
         %Table{end_player_pos: nil, next_player_pos: next_player_pos} = table,
         false
       ) do
    %Table{table | end_player_pos: next_player_pos}
  end

  # 玩家raise的情况下，重新来一轮新的行动
  defp maybe_set_end_player_pos(
         %Table{next_player_pos: next_player_pos} = table,
         true
       ) do
    %Table{table | end_player_pos: next_player_pos}
  end

  # 其余情况，玩家普通check平跟call都不改变最终本轮结束位置
  defp maybe_set_end_player_pos(table, false) do
    table
  end

  defp move_next_action_player_pos(
         %Table{num_players: total, next_player_pos: player_pos} = table
       ) do
    %Table{table | next_player_pos: next_pos(total, player_pos)}
  end

  defp force_bet_sb_and_bb(
         %Table{sb_amount: sb_amount, bb_amount: bb_amount, sb_pos: sb_pos, bb_pos: bb_pos} =
           table
       ) do
    table =
      table
      |> make_player_bet(sb_pos, sb_amount)
      |> make_player_bet(bb_pos, bb_amount)

    %Table{table | current_call_amount: bb_amount}
  end

  defp make_player_bet(table, pos, amount) do
    table = update_in(table.players[pos], &do_player_bet(&1, amount))

    %Table{table | current_street_bet: table.current_street_bet + amount}
    |> maybe_update_call_amount(pos)
  end

  defp do_player_bet(%Player{chips: chips, current_street_bet: already_bet} = player, amount)
       when chips >= amount do
    %Player{player | chips: chips - amount, current_street_bet: already_bet + amount}
  end

  defp maybe_update_call_amount(table, pos) do
    player = get_player_at_pos(table, pos)

    case player.current_street_bet > table.current_call_amount do
      true ->
        %Table{table | current_call_amount: player.current_street_bet}

      false ->
        table
    end
  end

  defp get_player_at_pos(table, pos) do
    table.players[pos]
  end

  defp player_amount_to_call(table, pos) do
    player = get_player_at_pos(table, pos)
    table.current_call_amount - player.current_street_bet
  end

  # 二人单挑只有第一次行动从button（小盲）开始
  defp reset_street_action_pos(
         %Table{num_players: 2, current_street: :preflop, button_pos: button_pos} = table
       ) do
    %Table{table | end_player_pos: nil, next_player_pos: button_pos}
  end

  # 之后的几条街都是大盲（非button位）开始
  defp reset_street_action_pos(%Table{num_players: 2, button_pos: button_pos} = table) do
    %Table{
      table
      | end_player_pos: nil,
        next_player_pos: next_pos(2, button_pos)
    }
  end

  # ============ 通用类帮助函数helper functions =========
  defp from_players_input_data(players_data) do
    Enum.reduce(players_data, Map.new(), fn {pos, chips}, acc ->
      Map.put(acc, pos, %Player{pos: pos, chips: chips})
    end)
  end

  defp next_pos(total, pos), do: Integer.mod(pos + 1, total)
end
