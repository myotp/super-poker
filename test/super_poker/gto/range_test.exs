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

  describe "产生高牌非对子组合" do
    test "AK+ 产生A-K的不同组合共16种" do
      hands = Range.from_string("AK+")
      assert Enum.count(hands) == 16
    end

    test "AQ+ 产生AK AQ不同组合共32种" do
      hands = Range.from_string("AQ+")
      assert Enum.count(hands) == 32
    end

    test "KQ+ 产生AK AQ KQ不同组合共48种" do
      hands = Range.from_string("KQ+")
      assert Enum.count(hands) == 48
    end

    test "KQ 只产生KQ不同组合共16种" do
      hands = Range.from_string("KQ")
      assert Enum.count(hands) == 16
    end
  end

  describe "产生花色限制" do
    test "AKs 只产生AK同花色组合共4种" do
      hands = Range.from_string("AKs")
      assert Enum.count(hands) == 4
    end

    test "AQs+ 产生同花色 AK AQ共8种组合" do
      hands = Range.from_string("AQs+")
      assert Enum.count(hands) == 8
    end

    test "KQs+ 产生同花色 AK AQ KQ共12种组合" do
      hands = Range.from_string("KQs+")
      assert Enum.count(hands) == 12
    end

    test "AKo 产生AK不同花色组合共12种" do
      hands = Range.from_string("AKo")
      assert Enum.count(hands) == 12
    end
  end

  describe "混合对子与高牌范围" do
    test "AA+/AK+ 产生AA的6种组合以及AK+的12种组合" do
      hands = Range.from_string("AA+/AK+")
      assert Enum.count(hands) == 6 + 16
    end

    test "QQ+/KQ+ 产生QKA对子6x3=18种组合，以及KQ+的组合48种" do
      hands = Range.from_string("QQ+/KQ+")
      assert Enum.count(hands) == 6 * 3 + 48
    end
  end

  describe "范围产生大检查" do
    test "22+/32+ 产生全部总共1326种组合" do
      hands = Range.from_string("22+/32+")
      assert Enum.count(hands) == 1326
    end
  end
end
