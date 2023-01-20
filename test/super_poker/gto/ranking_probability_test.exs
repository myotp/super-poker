defmodule SuperPoker.Gto.RankingProbabilityTest do
  use ExUnit.Case

  alias SuperPoker.Gto.RankingProbability

  test "测试7张手牌组成牌型的可能" do
    assert %{pair: pair_count} = RankingProbability.hand_types(100)
    assert pair_count > 0
  end
end
