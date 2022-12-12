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
      assert rules.current_action_pos == 0
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

  describe "UTG玩家也就是二人对战中的小盲位行动开始" do
    test "UTG玩家call更新筹码统计" do
      rules = Rules1v1.new([{0, 100}, {1, 100}], 0, {10, 20})
      # 牌局建立，小盲出10块，大盲出20，然后小盲位先行动
      assert rules.next_action == {:player, 0, [{:call, 10} | @user_default_actions]}
      rules = Rules1v1.handle_action(rules, {:player, 0, {:call, 10}})
      assert rules.players[0].chips == 80
      assert rules.players[0].current_street_bet == 20
      assert rules.players[0].status == :active
      assert rules.pot == 0
      assert rules.current_call_amount == 20
      assert rules.current_street_bet == 10 + 20 + 10
    end

    test "UTG玩家简单call之后轮到大盲位行动" do
      rules = Rules1v1.new([{0, 100}, {1, 100}], 0, {10, 20})
      rules = Rules1v1.handle_action(rules, {:player, 0, {:call, 10}})
      # 小盲位call了10块之后，轮到大盲位行动，可以check
      assert rules.next_action == {:player, 1, [:check | @user_default_actions]}
    end
  end

  describe "二人对战第一回合轮流交互" do
    test "小盲call大盲check回合结束即将发牌flop" do
      rules =
        Rules1v1.new([{0, 100}, {1, 100}], 0, {10, 20})
        |> Rules1v1.handle_action({:player, 0, {:call, 10}})
        |> Rules1v1.handle_action({:player, 1, :check})

      assert rules.next_action == {:table, {:deal, :flop}}
    end
  end

  describe "二人对战轮流行动多回合" do
    test "最简单主线流程验证到最终show-hands状态" do
      rules =
        Rules1v1.new([{0, 100}, {1, 100}], 0, {10, 20})
        |> Rules1v1.handle_action({:player, 0, {:call, 10}})
        |> Rules1v1.handle_action({:player, 1, :check})

      assert rules.next_action == {:table, {:deal, :flop}}

      # 发牌flop两玩家check
      rules =
        rules
        |> Rules1v1.handle_action({:table, {:deal, :flop}})
        |> Rules1v1.handle_action({:player, 1, :check})
        |> Rules1v1.handle_action({:player, 0, :check})

      assert rules.next_action == {:table, {:deal, :turn}}

      # 发turn牌两玩家继续check
      rules =
        rules
        |> Rules1v1.handle_action({:table, {:deal, :turn}})
        |> Rules1v1.handle_action({:player, 1, :check})
        |> Rules1v1.handle_action({:player, 0, :check})

      assert rules.next_action == {:table, {:deal, :river}}

      # 最终发完river牌两玩家继续check之后进入show_hands阶段
      rules =
        rules
        |> Rules1v1.handle_action({:table, {:deal, :river}})
        |> Rules1v1.handle_action({:player, 1, :check})
        |> Rules1v1.handle_action({:player, 0, :check})

      assert rules.next_action == {:table, {:show_hands, {[0, 1], 40, [{0, 80}, {1, 80}]}}}
    end
  end
end
