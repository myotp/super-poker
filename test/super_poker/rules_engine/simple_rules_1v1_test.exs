defmodule SuperPoker.RulesEngine.SimpleRules1v1Test do
  use ExUnit.Case
  alias SuperPoker.RulesEngine.SimpleRules1v1, as: Rules

  describe "new/1" do
    test "初始牌局触发正确场景" do
      table = Rules.new([{0, 100}, {1, 200}], 0, {5, 10})
      assert table.pot == 0
      assert table.next_action == {:table, {:notify_blind_bet, %{0 => 5, 1 => 10}}}
    end
  end

  describe "二人对战正确处理大小盲下注" do
    test "验证基本大小盲处理" do
      table =
        Rules.new([{0, 100}, {1, 200}], 0, {5, 10})
        |> Rules.handle_action(:notify_blind_bet_done)

      # 仅仅是大小盲下注完毕，preflop尚未完成，pot仍为0，筹码都在自家门口临时摆放区
      assert table.pot == 0
      assert table.current_street_bet == 15
      # button为小盲，正确下注小盲金额
      assert table.players[0].chips == 95
      assert table.players[1].chips == 190
    end

    test "验证下一步事件正确" do
      table =
        Rules.new([{0, 100}, {1, 200}], 0, {5, 10})
        |> Rules.handle_action(:notify_blind_bet_done)

      assert table.next_action == {:player, {0, [{:call, 5}, :raise, :fold]}}
    end
  end
end
