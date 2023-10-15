defmodule SuperPoker.IrcDataset.PlayerActionsTest do
  use ExUnit.Case

  alias SuperPoker.IrcDataset.PlayerActions

  describe "parse/1" do
    test "二人玩家到最后showhands" do
      action_str = "Jak       820830094  2  1 Bc  kc    kc    k          850   40   80 7c Ac"

      assert %PlayerActions{
               username: "Jak",
               game_id: 820_830_094,
               num_players: 2,
               pos: 1,
               preflop: "Bc",
               flop: "kc",
               turn: "kc",
               river: "k",
               bankroll: 850,
               total_bet: 40,
               winnings: 80,
               hole_cards: "7C AC"
             } = PlayerActions.parse(action_str)
    end

    test "中途fold则没有后续动作" do
      action_str = "ZhaoYun   975790230  6  2 B   -     -     -         2671   20   30 "

      assert %PlayerActions{
               preflop: "B",
               flop: nil,
               turn: nil,
               river: nil,
               hole_cards: nil
             } = PlayerActions.parse(action_str)
    end
  end
end
