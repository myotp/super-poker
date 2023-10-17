defmodule SuperPoker.HandHistory.PokerstarsExporterTest do
  use ExUnit.Case

  alias SuperPoker.HandHistory.PokerstarsExporter
  alias SuperPoker.HandHistory.HandHistory

  describe "to_string/1" do
    test "简单fold" do
      hand_history = %HandHistory{
        game_id: 12345,
        sb_amount: 2.5,
        bb_amount: 5,
        start_time: NaiveDateTime.new!(1999, 12, 31, 23, 59, 59)
      }

      assert PokerstarsExporter.to_string(hand_history) ==
               """
               SuperPoker Hand #12345:  Hold'em No Limit ($2.50/$5.00 USD) - 1999-12-31 23:59:59
               Table 'Rigel' 6-max Seat #4 is the button
               Seat 1: Anna ($1091.61 in chips)
               Seat 2: Bob ($581.64 in chips)
               """
    end
  end

  describe "action_to_string/1" do
    test "deal flop" do
      assert PokerstarsExporter.action_to_string({:deal, :flop, "AH KH 9H"}) ==
               "*** FLOP *** [Ah Kh 9h]"
    end

    test "deal turn" do
      assert PokerstarsExporter.action_to_string({:deal, :turn, "AH KH 9H 8H"}) ==
               "*** TURN *** [Ah Kh 9h] [8h]"
    end

    test "deal river" do
      assert PokerstarsExporter.action_to_string({:deal, :river, "AH KH 9H 8H 7H"}) ==
               "*** RIVER *** [Ah Kh 9h 8h] [7h]"
    end

    test "check" do
      assert PokerstarsExporter.action_to_string({:player, "Anna", :check}) == "Anna: checks"
    end

    test "call" do
      assert PokerstarsExporter.action_to_string({:player, "Anna", {:call, 0.05}}) ==
               "Anna: calls $0.05"
    end
  end
end
