defmodule SuperPoker.Gto.EquityCalculatorTest do
  use ExUnit.Case

  alias SuperPoker.Gto.EquityCalculator
  alias SuperPoker.Core.Hand

  @allowed_deviation_for_test 3

  describe "preflop翻牌前equity计算" do
    test "AK vs 55" do
      hand_ak = Hand.from_string("AH KD")
      hand_55 = Hand.from_string("5S 5C")
      {hand_ak_equity, hand_55_equity} = EquityCalculator.preflop_hand_vs_hand(hand_ak, hand_55)
      assert close_to?(hand_ak_equity, 45) == true
      assert close_to?(hand_55_equity, 55) == true
    end
  end

  defp close_to?(x, expected, deviation \\ @allowed_deviation_for_test) do
    case x > expected - deviation and x < expected + deviation do
      true ->
        true

      false ->
        {false, x, expected}
    end
  end
end
