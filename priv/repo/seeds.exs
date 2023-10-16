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
alias SuperPoker.IrcDataset.IrcPlayerActions
alias SuperPoker.IrcDataset.IrcGame

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
