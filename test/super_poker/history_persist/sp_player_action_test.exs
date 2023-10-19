defmodule SuperPoker.HistoryPersist.SpPlayerActionTest do
  use SuperPoker.DataCase

  alias SuperPoker.HistoryPersist.SpGame
  alias SuperPoker.HistoryPersist.SpPlayerAction
  alias SuperPoker.HistoryPersist.SpPlayerAction.PlayerAction
  alias SuperPoker.HistoryPersist.Query

  describe "t" do
    test "save_player_actions" do
      game_history_attrs = %{
        start_time: NaiveDateTime.from_iso8601!("1999-12-31 12:59:59"),
        button_pos: 2,
        sb_amount: 0.05,
        bb_amount: 0.10,
        blinds: [%{username: "Anna", amount: 0.1}, %{username: "Lucas", amount: 0.05}],
        community_cards: "AH KH QH JH TH",
        players: [
          %{pos: 1, username: "Anna", chips: 10.0, hole_cards: "3C 2C"},
          %{pos: 2, username: "Lucas", chips: 15.0, hole_cards: "3D 2D"}
        ]
      }

      {:ok, %SpGame{id: game_id}} = SpGame.save_game_history(game_history_attrs)

      attrs = %{
        username: "Anna",
        preflop: [%{action: "check", amount: 0}],
        flop: [%{action: "check", amount: 0}],
        turn: [%{action: "raise", amount: 10}, %{action: "call", amount: 5}],
        river: [
          %{action: "raise", amount: 10},
          %{action: "raise", amount: 20},
          %{action: "raise", amount: 30}
        ]
      }

      assert {:ok, _} =
               SpPlayerAction.save_player_actions(game_id, attrs)

      assert %SpPlayerAction{
               preflop: [
                 %PlayerAction{action: :check, amount: 0.0}
               ],
               flop: [
                 %PlayerAction{action: :check, amount: 0.0}
               ],
               turn: [
                 %PlayerAction{action: :raise, amount: 10.0},
                 %PlayerAction{action: :call, amount: 5.0}
               ],
               river: [
                 %PlayerAction{action: :raise, amount: 10.0},
                 %PlayerAction{action: :raise, amount: 20.0},
                 %PlayerAction{action: :raise, amount: 30.0}
               ]
             } =
               Query.find_player_actions(game_id, "Anna")
    end
  end
end
