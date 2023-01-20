defmodule SuperPoker.Gto.ComboTest do
  use ExUnit.Case

  alias SuperPoker.Core.Card
  alias SuperPoker.Gto.{Range, Combo}

  describe "去除range组合当中阻挡牌冲突组合" do
    test "AA+ 共六种组合去除一对AK影响只剩3种组合" do
      a = Card.from_string("AS")
      k = Card.from_string("KH")

      hands =
        Range.from_string("AA+")
        |> Combo.remove_blocker_combos([a, k])

      assert Enum.count(hands) == 3
      assert a not in List.flatten(hands)
    end
  end
end
