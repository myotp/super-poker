defmodule SuperPoker.IrcDataset.GamePlayers do
  defstruct [:game_id, :num_players, :players]

  def parse(str) do
    try do
      [game_id, num_players | players] = String.split(str, " ", trim: true)
      game_id = String.to_integer(game_id)
      num_players = String.to_integer(num_players)
      ^num_players = Enum.count(players)
      %__MODULE__{game_id: game_id, num_players: num_players, players: players}
    rescue
      _ ->
        IO.puts("HELP! #{str}")
        nil
    end
  end
end
