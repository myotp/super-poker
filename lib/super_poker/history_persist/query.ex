defmodule SuperPoker.HistoryPersist.Query do
  import Ecto.Query

  alias SuperPoker.Repo
  alias SuperPoker.HistoryPersist.SpGamePlayer

  def find_game_player(game_id, username) do
    query =
      from p in SpGamePlayer,
        where: p.game_id == ^game_id and p.username == ^username

    Repo.one(query)
  end
end
