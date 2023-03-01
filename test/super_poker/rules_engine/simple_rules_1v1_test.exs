defmodule SuperPoker.RulesEngine.SimpleRules1v1Test do
  use ExUnit.Case
  alias SuperPoker.RulesEngine.SimpleRules1v1, as: Rules

  describe "new/1" do
    test "初始牌局触发正确场景" do
      table = Rules.new(%{0 => 100, 1 => 200}, 0, {5, 10})
      assert table.pot == 0
      assert table.next_action == {:table, {:notify_blind_bet, %{0 => 5, 1 => 10}}}
    end
  end

  describe "二人对战正确处理大小盲下注" do
    test "验证基本大小盲处理" do
      table =
        Rules.new(%{0 => 100, 1 => 200}, 0, {5, 10})
        |> Rules.handle_action({:table, :notify_blind_bet_done})

      # 仅仅是大小盲下注完毕，preflop尚未完成，pot仍为0，筹码都在自家门口临时摆放区
      assert table.pot == 0
      assert table.current_street_bet == 15
      # button为小盲，正确下注小盲金额
      assert table.players[0].chips == 95
      assert table.players[1].chips == 190

      # 当前轮下注，尚未进入pot池子当中
      assert table.pot == 0
      assert table.current_street_bet == 15

      # 盲注之后，当前call的值为大盲
      assert table.current_call_amount == 10
    end

    test "验证下一步事件正确" do
      table =
        Rules.new(%{0 => 100, 1 => 200}, 0, {5, 10})
        |> Rules.handle_action({:table, :notify_blind_bet_done})

      assert table.current_call_amount == 10
      assert table.next_action == {:player, {0, [:fold, {:call, 5}, :raise]}}
    end
  end

  describe "验证首回合小盲玩家优先行动玩家交互事件正确" do
    test "小盲玩家fold" do
      table =
        Rules.new(%{0 => 100, 1 => 200}, 0, {5, 10})
        |> Rules.handle_action({:table, :notify_blind_bet_done})
        |> Rules.handle_action({:player, {0, :fold}})

      assert table.next_action == {:winner, 1, %{0 => 95, 1 => 205}}
    end

    test "小盲玩家call平跟" do
      table =
        Rules.new(%{0 => 100, 1 => 200}, 0, {5, 10})
        |> Rules.handle_action({:table, :notify_blind_bet_done})
        |> Rules.handle_action({:player, {0, :call}})

      # 当前下注尚未进入最终pot池子
      assert table.pot == 0
      assert table.current_street_bet == 20
      # 验证该轮到大盲玩家行动
      assert table.next_action == {:player, {1, [:fold, :check, :raise]}}
    end

    test "小盲玩家raise加注" do
      bb_amount = 20
      sb_amount = 10

      table =
        Rules.new(%{0 => 100, 1 => 200}, 0, {sb_amount, bb_amount})
        |> Rules.handle_action({:table, :notify_blind_bet_done})
        |> Rules.handle_action({:player, {0, {:raise, 35}}})

      # 小盲玩家总共下注计算
      amount_for_player_0_to_call = bb_amount - sb_amount
      player_0_force_sb_bet = sb_amount
      player_0_total_bet = 35 + amount_for_player_0_to_call + player_0_force_sb_bet

      # 小盲玩家加注之后，当前总共需要call的值就为小盲玩家到这里总下注值
      assert table.current_call_amount == player_0_total_bet

      # raise需要隐含额外加上call的金额
      assert table.next_action ==
               {:player, {1, [:fold, {:call, player_0_total_bet - bb_amount}, :raise]}}
    end
  end
end
