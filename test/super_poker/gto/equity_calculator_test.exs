defmodule SuperPoker.Gto.EquityCalculatorTest do
  use ExUnit.Case

  alias SuperPoker.Gto.EquityCalculator
  alias SuperPoker.Core.Hand

  @allowed_deviation_for_test 3

  describe "preflop翻牌前equity计算" do
    test "手牌vs手牌 AKo vs 55 大约AKo有45%的胜率" do
      hand_ak = Hand.from_string("AH KD")
      hand_55 = Hand.from_string("5S 5C")
      {hand_ak_equity, hand_55_equity} = EquityCalculator.preflop_hand_vs_hand(hand_ak, hand_55)
      assert close_to?(hand_ak_equity, 45) == true
      assert close_to?(hand_55_equity, 55) == true
    end

    test "手牌vs范围 AKo 对 JJ+/AK 范围 AKo大约有40%胜率" do
      hand_ak = Hand.from_string("AH KD")
      range_jj_ak = "JJ+/AK"

      {hand_ak_equity, hand_range_jj_ak_equity} =
        EquityCalculator.preflop_hand_vs_range(hand_ak, range_jj_ak)

      assert close_to?(hand_ak_equity, 40) == true
      assert close_to?(hand_range_jj_ak_equity, 60) == true
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
