defmodule SuperPoker.IrcDataset.IrcGame do
  use Ecto.Schema
  import Ecto.Changeset

  alias SuperPoker.IrcDataset.GamePlayers
  alias SuperPoker.Repo

  @fields [:game_id, :num_players, :players]

  schema "irc_games" do
    field :game_id, :integer
    field :num_players, :integer
    field :players, {:array, :string}
  end

  def save_game_players(%GamePlayers{} = game_players) do
    game_players
    |> Map.from_struct()
    |> changeset()
    |> Repo.insert(conflict_target: [:game_id], on_conflict: :nothing)
  end

  def changeset(irc_game \\ %__MODULE__{}, attrs) do
    irc_game
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:game_id)
  end
end
