defmodule SuperPoker.History.HhsmithyExporterTest do
  use ExUnit.Case

  alias SuperPoker.History.HhsmithyExporter
  alias SuperPoker.History.GameHistory

  describe "to_string/1" do
    test "简单fold" do
      game_history = %GameHistory{
        game_id: 12345,
        sb_amount: 2.5,
        bb_amount: 5,
        start_time: NaiveDateTime.new!(1999, 12, 31, 23, 59, 59)
      }

      assert HhsmithyExporter.to_string(game_history) ==
               """
               SuperPoker Hand #12345:  Hold'em No Limit ($2.50/$5.00 USD) - 1999-12-31 23:59:59
               Table 'Rigel' 6-max Seat #4 is the button
               Seat 1: Anna ($1091.61 in chips)
               Seat 2: Bob ($581.64 in chips)
               """
    end
  end
end
