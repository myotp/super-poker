defmodule SuperPoker.Gto.HandsTest do
  use ExUnit.Case

  alias SuperPoker.Core.Hand
  alias SuperPoker.Gto.{Range, Hands}

  describe "去除range组合当中阻挡牌冲突组合" do
    test "AA+ 共六种组合去除一对AK影响只剩3种组合" do
      ak = Hand.from_string("AS KH")

      hands =
        Range.from_string("AA+")
        |> Hands.remove_blocker_combos(ak)

      assert Enum.count(hands) == 3
    end
  end
end
