defmodule SuperPoker.IrcDataset.IrcGame do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias SuperPoker.IrcDataset.GamePlayers
  alias SuperPoker.Repo
  alias SuperPoker.IrcDataset.IrcGame
  alias SuperPoker.IrcDataset.IrcTable
  alias SuperPoker.IrcDataset.IrcPlayerActions

  schema "irc_games" do
    field :game_id, :integer
    field :num_players, :integer
    field :players, {:array, :string}
    has_many :players_actions, IrcPlayerActions, references: :game_id, foreign_key: :game_id
    has_one :table, IrcTable, references: :game_id, foreign_key: :game_id
  end

  def save_game_players(%GamePlayers{} = game_players) do
    game_players
    |> Map.from_struct()
    |> changeset()
    |> Repo.insert(conflict_target: [:game_id], on_conflict: :nothing)
  end

  defp all_fields() do
    __MODULE__.__schema__(:fields) -- [:id]
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, all_fields())
    |> validate_required(all_fields())
    |> unique_constraint(:game_id)
  end

  def load_game_with_player_actions(game_id) do
    query =
      from game in IrcGame,
        where: game.game_id == ^game_id

    Repo.one(query)
    |> Repo.preload([:players_actions, :table])
  end
end
