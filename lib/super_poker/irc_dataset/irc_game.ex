defmodule SuperPoker.IrcDataset.IrcGame do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias SuperPoker.IrcDataset.GamePlayers
  alias SuperPoker.Repo
  alias SuperPoker.IrcDataset.IrcGame
  alias SuperPoker.IrcDataset.IrcPlayerActions

  @fields [:game_id, :num_players, :players]

  schema "irc_games" do
    field :game_id, :integer
    field :num_players, :integer
    field :players, {:array, :string}
    has_many :players_actions, IrcPlayerActions, references: :game_id, foreign_key: :game_id
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

  def load_game_with_player_actions(game_id) do
    query =
      from game in IrcGame,
        where: game.game_id == ^game_id

    Repo.one(query)
    |> Repo.preload(:players_actions)
  end
end
