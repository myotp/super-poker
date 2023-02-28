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
      players: players_from_tuple_list(players_data)
    }
    |> set_sb_and_bb_pos_for_only_two_players_game()
    |> decide_next_action()
  end

  # ============ 主要的基于状态机的决定当下操作 ============
  # 当pot为空的时候，处于游戏最初状态，需要大小盲下注，这里也产生事件，好让游戏服务器通知各个玩家大小盲下注
  defp decide_next_action(
         %Table{
           pot: 0,
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
  defp decide_next_action(%Table{next_player_pos: nil} = table) do
    decide_next_player_action(table)
  end

  defp decide_next_player_action(%Table{} = table) do
    # TODO
    table
  end

  # ============ 处理外部事件之后的规则推进 ===========
  def handle_action(table, :notify_blind_bet_done) do
    table
    |> reset_current_street_bet_info()
    |> force_bet_sb_and_bb()
    |> reset_street_action_pos()
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
  end

  defp do_player_bet(%Player{chips: chips, current_street_bet: already_bet} = player, amount)
       when chips >= amount do
    %Player{player | chips: chips - amount, current_street_bet: already_bet + amount}
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
  defp players_from_tuple_list(players_data) do
    Enum.reduce(players_data, Map.new(), fn {pos, chips}, acc ->
      Map.put(acc, pos, %Player{pos: pos, chips: chips})
    end)
  end

  defp next_pos(total, pos), do: Integer.mod(pos + 1, total)
end
