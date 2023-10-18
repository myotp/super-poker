defmodule SuperPoker.HistoryPersist.SpPlayerAction do
  use Ecto.Schema

  import Ecto.Changeset

  alias SuperPoker.HistoryPersist.SpPlayerAction.PlayerAction
  alias SuperPoker.Repo

  @primary_key false
  schema "sp_player_actions" do
    field :game_id, :id, primary_key: true
    field :username, :string, primary_key: true
    embeds_many :preflop, PlayerAction
    embeds_many :flop, PlayerAction
    embeds_many :turn, PlayerAction
    embeds_many :river, PlayerAction
  end

  defmodule PlayerAction do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field :action, :string
      field :amount, :float
    end

    def changeset(action, attrs) do
      action
      |> cast(attrs, [:action, :amount])
    end
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:game_id, :username])
    |> cast_embed(:preflop)
    |> cast_embed(:flop)
    |> cast_embed(:turn)
    |> cast_embed(:river)
  end

  def save_player_actions(attrs) do
    attrs
    |> changeset()
    |> Repo.insert()
  end
end
