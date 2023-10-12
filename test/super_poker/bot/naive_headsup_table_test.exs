defmodule SuperPoker.Bot.NaiveHeadsupTableTest do
  alias SuperPoker.Bot.NaiveHeadsupTable
  use ExUnit.Case

  describe "new/1" do
    test "创建开局table" do
      assert %NaiveHeadsupTable{
               round: :preflop,
               pot: 0,
               my_chips: 100,
               oppo_chips: 200,
               amount_to_call: 0,
               hole_cards: [],
               community_cards: []
             } = NaiveHeadsupTable.new(100, 200)
    end
  end

  describe "make_bet/3" do
    test "双方轮流下注或者大小盲同时下注" do
      table = NaiveHeadsupTable.new(100, 200)
      assert table.pot == 0
      assert table.my_chips == 100
      assert table.oppo_chips == 200
      table = NaiveHeadsupTable.make_bet(table, :me, 0.5)
      assert table.pot == 0.5
      assert table.my_chips == 99.5
      assert table.oppo_chips == 200
      table = NaiveHeadsupTable.make_bet(table, :oppo, 1)
      assert table.pot == 1.5
      assert table.my_chips == 99.5
      assert table.oppo_chips == 199
    end
  end

  describe "update_amount_to_call/2" do
    test "由上层拿到todo actions后更新amount_to_call" do
      table = NaiveHeadsupTable.new(100, 200)
      table = NaiveHeadsupTable.update_amount_to_call(table, 0.5)
      assert table.amount_to_call == 0.5
    end
  end

  describe "deal_hole_cards/2" do
    test "发手牌" do
      table = NaiveHeadsupTable.new(100, 200)
      table = NaiveHeadsupTable.deal_hole_cards(table, [1, 2])
      assert table.hole_cards == [1, 2]
    end
  end

  describe "deal_community_cards/2" do
    test "完整发牌" do
      table = NaiveHeadsupTable.new(100, 200)
      assert table.round == :preflop
      assert table.community_cards == []
      table = NaiveHeadsupTable.deal_community_cards(table, [1, 2, 3])
      assert table.round == :flop
      assert table.community_cards == [1, 2, 3]
      table = NaiveHeadsupTable.deal_community_cards(table, [4])
      assert table.round == :turn
      assert table.community_cards == [1, 2, 3, 4]
      table = NaiveHeadsupTable.deal_community_cards(table, [5])
      assert table.round == :river
      assert table.community_cards == [1, 2, 3, 4, 5]
    end
  end
end
