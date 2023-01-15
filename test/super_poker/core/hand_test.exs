defmodule SuperPoker.Core.HandTest do
  use ExUnit.Case
  doctest SuperPoker.Core.Hand
  alias SuperPoker.Core.Hand

  describe "牌型之间比较大小" do
    test "皇家同花顺比任何都大" do
      p1_hand = Hand.from_string("AH KH")
      community_cards = Hand.from_string("QH JH TH 2S 2D")
      p2_hand = Hand.from_string("7H 8H")
      assert Hand.compare(p1_hand, p2_hand, community_cards) == :win
      assert Hand.compare(p2_hand, p1_hand, community_cards) == :lose
    end
  end

  describe "牌型内部踢脚比较大小" do
    test "同样葫芦优先看三张的大小" do
      p1_hand = Hand.from_string("AH AS")
      community_cards = Hand.from_string("AD JH TH 2S 2D")
      p2_hand = Hand.from_string("2H TD")
      assert Hand.compare(p1_hand, p2_hand, community_cards) == :win
    end

    test "单对优先比对子本身大小" do
      p1_hand = Hand.from_string("9H KS")
      community_cards = Hand.from_string("QS 9D 5S 4H 2D")
      p2_hand = Hand.from_string("5D AH")
      assert Hand.compare(p1_hand, p2_hand, community_cards) == :win
    end

    test "对子一样的时候比第一个大踢脚" do
      p1_hand = Hand.from_string("AH KS")
      community_cards = Hand.from_string("AS 9D 5S 4H 2D")
      p2_hand = Hand.from_string("AD QH")
      assert Hand.compare(p1_hand, p2_hand, community_cards) == :win
    end

    test "对子与第一踢脚相同时候比第二踢脚" do
      p1_hand = Hand.from_string("AH QS")
      community_cards = Hand.from_string("AS KH 5S 4H 2D")
      p2_hand = Hand.from_string("AD JD")
      assert Hand.compare(p1_hand, p2_hand, community_cards) == :win
    end
  end

  # TODO
  describe "四条比较看手牌情况而定" do
  end

  describe "简单排序" do
    test "按照黑红梅方顺序给手牌排序才能保证后续去除重复时候的正确" do
      [c1, c2, c3, c4] = Hand.from_string("AD AC AH AS") |> Hand.sort()
      assert c1.suit == :spades
      assert c2.suit == :hearts
      assert c3.suit == :clubs
      assert c4.suit == :diamonds
    end
  end
end
