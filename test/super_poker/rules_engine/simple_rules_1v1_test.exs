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

      # 小盲玩家初次行动之后，设置正确结束位置
      assert table.end_player_pos == 0

      # raise需要隐含额外加上call的金额
      assert table.next_action ==
               {:player, {1, [:fold, {:call, player_0_total_bet - bb_amount}, :raise]}}
    end
  end

  describe "验证首回合轮到大盲玩家行动之后事件正确" do
    test "小盲raise大盲玩家fold, 则小盲玩家赢下" do
      table =
        Rules.new(%{0 => 100, 1 => 200}, 0, {5, 10})
        |> Rules.handle_action({:table, :notify_blind_bet_done})
        |> Rules.handle_action({:player, {0, {:raise, 35}}})
        |> Rules.handle_action({:player, {1, :fold}})

      assert table.next_action == {:winner, 0, %{0 => 110, 1 => 190}}
    end

    test "小盲raise大盲玩家call平跟, 该轮到牌桌发flop三张牌" do
      table =
        Rules.new(%{0 => 100, 1 => 200}, 0, {5, 10})
        |> Rules.handle_action({:table, :notify_blind_bet_done})
        |> Rules.handle_action({:player, {0, {:raise, 35}}})
        |> Rules.handle_action({:player, {1, :call}})

      assert table.next_action == {:table, {:deal, :flop}}
    end

    test "小盲call大盲玩家raise, 小盲再次call, 则轮到牌桌发flop三张牌" do
      table =
        Rules.new(%{0 => 100, 1 => 200}, 0, {5, 10})
        |> Rules.handle_action({:table, :notify_blind_bet_done})
        |> Rules.handle_action({:player, {0, :call}})
        |> Rules.handle_action({:player, {1, {:raise, 40}}})

      # 大盲玩家3bet之后，轮到小盲玩家再次行动
      assert table.next_action == {:player, {0, [:fold, {:call, 40}, :raise]}}

      # 再次轮到小盲玩家, 普通平call之后, preflop下注结束，该发flop三张牌了
      table = Rules.handle_action(table, {:player, {0, :call}})
      assert table.next_action == {:table, {:deal, :flop}}
    end
  end

  describe "验证preflop下注回合结束" do
    test "正确把下注移入pot" do
      table =
        Rules.new(%{0 => 100, 1 => 200}, 0, {5, 10})
        |> Rules.handle_action({:table, :notify_blind_bet_done})
        |> Rules.handle_action({:player, {0, :call}})
        |> Rules.handle_action({:player, {1, :check}})

      assert table.next_action == {:table, {:deal, :flop}}
      # 双方preflop下注共20
      assert table.current_street_bet == 0
      assert table.pot == 20
    end
  end

  describe "发flop之后新一轮下注开始" do
    test "OK" do
      table =
        Rules.new(%{0 => 100, 1 => 200}, 0, {5, 10})
        |> Rules.handle_action({:table, :notify_blind_bet_done})
        |> Rules.handle_action({:player, {0, :call}})
        |> Rules.handle_action({:player, {1, :check}})
        |> Rules.handle_action({:table, {:done, :flop}})

      # 新一轮行动开始
      assert table.next_player_pos == 1
      assert table.next_action == {:player, {1, [:fold, :check, :raise]}}
      # pot设置正确了已经
      assert table.pot == 20
      assert table.current_street_bet == 0
    end
  end

  describe "大综合流程整体验证" do
    test "双方交互直到最后摊牌" do
      # 启动新局，双方各500入场
      table = Rules.new(%{0 => 500, 1 => 500}, 0, {10, 20})
      # 初始金额验证
      assert table.pot == 0
      assert table.current_street_bet == 0
      # 验证桌子需要通知大小盲下注
      assert table.next_action == {:table, {:notify_blind_bet, %{0 => 10, 1 => 20}}}

      # 牌桌通知大小盲下注
      table = Rules.handle_action(table, {:table, :notify_blind_bet_done})
      assert table.pot == 0
      assert table.current_street_bet == 30
      # 小盲先行动, 可以fold, call, raise
      assert table.next_action == {:player, {0, [:fold, {:call, 10}, :raise]}}
      table = Rules.handle_action(table, {:player, {0, :call}})
      assert table.pot == 0
      assert table.current_street_bet == 40

      # 大盲简单check, 翻牌前下注结束
      table = Rules.handle_action(table, {:player, {1, :check}})
      # 下注处理, 翻牌前下注结束, 各人下注移入pot
      assert table.current_street_bet == 0
      assert table.pot == 40
      assert table.next_action == {:table, {:deal, :flop}}

      # 发牌flop之后, 该轮到大盲位先行动, button位永远最后行动
      # 这一轮双方check
      table = Rules.handle_action(table, {:table, {:done, :flop}})
      assert table.next_action == {:player, {1, [:fold, :check, :raise]}}
      table = Rules.handle_action(table, {:player, {1, :check}})
      assert table.next_action == {:player, {0, [:fold, :check, :raise]}}
      table = Rules.handle_action(table, {:player, {0, :check}})
      # flop下注回合结束
      assert table.pot == 40
      assert table.current_street_bet == 0
      assert table.next_action == {:table, {:deal, :turn}}

      # turn回合 check-bet-call
      table = Rules.handle_action(table, {:table, {:done, :turn}})
      assert table.next_action == {:player, {1, [:fold, :check, :raise]}}
      table = Rules.handle_action(table, {:player, {1, :check}})
      assert table.next_action == {:player, {0, [:fold, :check, :raise]}}
      # button下注15块, 我的简化，用raise实现
      table = Rules.handle_action(table, {:player, {0, {:raise, 15}}})
      assert table.pot == 40
      assert table.current_street_bet == 15
      assert table.next_action == {:player, {1, [:fold, {:call, 15}, :raise]}}
      table = Rules.handle_action(table, {:player, {1, :call}})
      assert table.pot == 40 + 15 + 15
      assert table.current_street_bet == 0
      assert table.next_action == {:table, {:deal, :river}}

      # river回合bet-call
      table = Rules.handle_action(table, {:table, {:done, :river}})
      assert table.next_action == {:player, {1, [:fold, :check, :raise]}}
      table = Rules.handle_action(table, {:player, {1, {:raise, 50}}})
      assert table.next_action == {:player, {0, [:fold, {:call, 50}, :raise]}}
      table = Rules.handle_action(table, {:player, {0, :call}})
      assert table.pot == 170
      assert table.current_street_bet == 0
      # 两玩家桌子，只要到最后，一定是二人一起
      assert table.next_action == {:table, {:show_hands, {170, %{0 => 415, 1 => 415}}}}
    end
  end
end
