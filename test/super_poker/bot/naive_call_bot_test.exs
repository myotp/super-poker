defmodule SuperPoker.Bot.NaiveCallBotTest do
  alias SuperPoker.Bot.NaiveCallBot
  alias SuperPoker.Bot.NaiveHeadsupTable

  use ExUnit.Case

  describe "make_decision/1" do
    test "简单下盲注" do
      table =
        NaiveHeadsupTable.new(100, 200)
        |> NaiveHeadsupTable.make_bet(:me, 0.5)
        |> NaiveHeadsupTable.make_bet(:oppo, 1)
        |> NaiveHeadsupTable.update_amount_to_call(0.5)

      assert NaiveCallBot.make_decision(%NaiveCallBot{table: table}) == :call
    end

    test "无需下注的时候check" do
      table =
        NaiveHeadsupTable.new(100, 200)
        |> NaiveHeadsupTable.update_amount_to_call(0)

      assert NaiveCallBot.make_decision(%NaiveCallBot{table: table}) == :check
    end
  end
end
