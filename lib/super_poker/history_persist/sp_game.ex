defmodule SuperPoker.HistoryPersist.SpGame do
  use Ecto.Schema
  import Ecto.Changeset

  alias SuperPoker.Repo
  alias SuperPoker.HistoryPersist.SpGamePlayer
  alias SuperPoker.HistoryPersist.SpPlayerAction

  schema "sp_games" do
    field :start_time, :naive_datetime
    field :button_pos, :integer
    field :sb_amount, :float
    field :bb_amount, :float
    field :community_cards, :string

    has_many :players, SpGamePlayer, foreign_key: :game_id, references: :id
    has_many :player_actions, SpPlayerAction, foreign_key: :game_id, references: :id
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

  def save_game_history(game_history) do
    game_history
    |> changeset()
    # 这个会自动调用默认SpGamePlayer.changeset/2当然也可以改
    |> cast_assoc(:players)
    |> Repo.insert()
  end

  def read_game_history_from_db(game_id) do
    Repo.get(__MODULE__, game_id)
    |> Repo.preload(:players)
    |> Repo.preload(:player_actions)
  end
end
