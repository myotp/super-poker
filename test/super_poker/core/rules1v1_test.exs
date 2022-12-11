defmodule SuperPoker.Core.Rules1v1Test do
  use ExUnit.Case

  alias SuperPoker.Core.Rules1v1

  @user_default_actions [:raise, :allin, :fold]

  describe "初始化二人对战牌局在Preflop玩家行动开始之前阶段" do
    test "游戏第一条街从preflop开始" do
      rules = Rules1v1.new([{0, 100}, {1, 100}], 0, {10, 20})
      assert rules.current_street == :preflop
    end

    test "测试基本玩家数量统计正确" do
      rules = Rules1v1.new([{0, 100}, {1, 100}], 0, {10, 20})
      assert rules.num_players == 2
    end

    test "只有两个玩家的时候，约定sb为button位置" do
      rules = Rules1v1.new([{0, 100}, {1, 100}], 0, {10, 20})
      assert rules.button_pos == 0
      assert rules.sb_pos == 0
      assert rules.bb_pos == 1

      rules = Rules1v1.new([{0, 100}, {1, 100}], 1, {10, 20})
      assert rules.button_pos == 1
      assert rules.sb_pos == 1
      assert rules.bb_pos == 0
    end

    test "只有两个玩家的时候，从sb开始，也就是button位开始" do
      rules = Rules1v1.new([{0, 100}, {1, 100}], 0, {10, 20})
      assert rules.start_action_pos == 0
      assert rules.next_action_pos == 0
    end

    test "盲注数量记录正确" do
      rules = Rules1v1.new([{0, 100}, {1, 100}], 0, {10, 20})
      assert rules.sb_amount == 10
      assert rules.bb_amount == 20
    end

    test "当前轮未结束前，牌桌上筹码尚未进入pot当中" do
      rules = Rules1v1.new([{0, 100}, {1, 100}], 0, {10, 20})
      assert rules.current_street_bet == 30
      assert rules.pot == 0
    end

    test "只有两个玩家的情况下，从小盲也就是button处开始" do
      rules = Rules1v1.new([{0, 100}, {1, 100}], 0, {10, 20})
      assert rules.next_action == {:player, 0, [{:call, 10} | @user_default_actions]}
    end

    test "正确更新玩家筹码信息" do
      rules = Rules1v1.new([{0, 100}, {1, 100}], 0, {10, 20})
      assert rules.current_street_bet == 30

      assert rules.players[0].chips == 90
      assert rules.players[0].current_street_bet == 10
      assert rules.players[0].status == :active

      assert rules.players[1].chips == 80
      assert rules.players[1].current_street_bet == 20
      assert rules.players[1].status == :active
    end
  end
end
