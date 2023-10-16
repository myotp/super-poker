defmodule SuperPoker.IrcDataset.IrcTable do
  use Ecto.Schema
  import Ecto.Changeset

  alias SuperPoker.IrcDataset.Table
  alias SuperPoker.Repo

  @primary_key false
  schema "irc_tables" do
    field :game_id, :integer, primary_key: true
    field :blind, :integer
    field :pot_after_preflop, :integer
    field :pot_after_flop, :integer
    field :pot_after_turn, :integer
    field :pot_after_river, :integer
    field :community_cards, :string
  end

  def save_table(%Table{} = table) do
    table
    |> Map.from_struct()
    |> changeset()
    |> Repo.insert(conflict_target: [:game_id], on_conflict: :nothing)
  end

  defp all_fields() do
    __MODULE__.__schema__(:fields)
  end

  def changeset(attrs) do
    %__MODULE__{}
    # 默认empty_values为[""]会把""当作NULL来处理
    |> cast(attrs, all_fields(), empty_values: [])
    # validate_required会把可能的"" community_cards当作违反约定
    |> validate_required(all_fields() -- [:community_cards])
    |> unique_constraint(:game_id, name: :irc_tables_pkey)
  end
end
