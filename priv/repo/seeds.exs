# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SuperPoker.Repo.insert!(%SuperPoker.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias SuperPoker.IrcDataset.GamePlayers
alias SuperPoker.IrcDataset.PlayerActions
alias SuperPoker.IrcDataset.Table
alias SuperPoker.IrcDataset.IrcPlayerActions
alias SuperPoker.IrcDataset.IrcGame
alias SuperPoker.IrcDataset.IrcTable
alias SuperPoker.HandHistory.HandHistory
alias SuperPoker.HistoryPersist

%GamePlayers{
  game_id: 8001,
  num_players: 2,
  players: ["Anna", "Bob"]
}
|> IrcGame.save_game_players()

%PlayerActions{
  username: "Anna",
  game_id: 8001,
  num_players: 2,
  pos: 1,
  preflop: "Bc",
  flop: "k",
  turn: "f",
  bankroll: 500,
  total_bet: 20,
  winnings: 0
}
|> IrcPlayerActions.save_player_actions()

%PlayerActions{
  username: "Bob",
  game_id: 8001,
  num_players: 2,
  pos: 2,
  preflop: "Bk",
  flop: "k",
  turn: nil,
  bankroll: 500,
  total_bet: 20,
  winnings: 40
}
|> IrcPlayerActions.save_player_actions()

%Table{
  game_id: 8001,
  blind: 2,
  pot_after_preflop: 10,
  pot_after_flop: 20,
  pot_after_turn: 30,
  pot_after_river: 40,
  community_cards: "AH KH QH JH TH"
}
|> IrcTable.save_table()

hand_history =
  %HandHistory{
    start_time: NaiveDateTime.from_iso8601!("2023-10-17 15:59:40"),
    players: [
      %{pos: 3, username: "Lucas", chips: 500},
      %{pos: 5, username: "Anna", chips: 600}
    ],
    button_pos: 5,
    sb_amount: 5,
    bb_amount: 10,
    blinds: %{"Anna" => 5, "Lucas" => 10},
    hole_cards: %{"Anna" => "3D 2D", "Lucas" => "AH QC"},
    community_cards: "QH 7H 5D 8C 9S",
    actions: [
      {:player, "Anna", {:call, 5}},
      {:player, "Lucas", :check},
      {:deal, :flop, "QH 7H 5D"},
      {:player, "Lucas", :check},
      {:player, "Anna", :check},
      {:deal, :turn, "QH 7H 5D 8C"},
      {:player, "Lucas", :check},
      {:player, "Anna", :check},
      {:deal, :river, "QH 7H 5D 8C 9S"},
      {:player, "Lucas", {:raise, 10}},
      {:player, "Anna", {:raise, 20}},
      {:player, "Lucas", {:raise, 50}},
      {:player, "Anna", {:call, 40}}
    ]
  }

HistoryPersist.save_hand_history(hand_history)
