defmodule SuperPoker.IrcDataset.GamePlayers do
  defstruct [:game_id, :num_players, :players]

  def parse(str) do
    with [game_id, num_players | players] <- String.split(str, " ", trim: true),
         game_id = String.to_integer(game_id),
         num_players = String.to_integer(num_players),
         ^num_players <- Enum.count(players) do
      %__MODULE__{game_id: game_id, num_players: num_players, players: players}
    else
      _ ->
        IO.puts("HELP! #{str}")
        nil
    end
  end
end
