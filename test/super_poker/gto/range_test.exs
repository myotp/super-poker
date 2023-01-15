defmodule SuperPoker.Gto.RangeTest do
  use ExUnit.Case

  alias SuperPoker.Gto.Range

  describe "产生对子" do
    test "AA+ 能够产生AA的不同花色的6种组合" do
      hands = Range.from_string("AA+")
      assert Enum.count(hands) == 6
    end

    test "KK+ 能够产生KK及AA的不同花色的共12种组合" do
      hands = Range.from_string("KK+")
      assert Enum.count(hands) == 12
    end

    test "TT+ 能够产生TJQKA的每个不同花色的共6x5=30种组合" do
      hands = Range.from_string("TT+")
      assert Enum.count(hands) == 30
    end
  end
end
