defmodule SuperPoker.HistoryPersist.SpGame do
  use Ecto.Schema
  import Ecto.Changeset
  alias SuperPoker.Repo

  schema "sp_games" do
    field :start_time, :naive_datetime
    field :button_pos, :integer
    field :sb_amount, :float
    field :bb_amount, :float
    field :community_cards, :string
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
    |> Repo.insert()
  end
end
