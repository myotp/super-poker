defmodule SuperPoker.HistoryPersist.SpGamePlayer do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  schema "sp_game_players" do
    # 不想反向获得
    # belongs_to :game, SpGame, foreign_key: :game_id, references: :id
    field :game_id, :id

    field :username, :string
    field :pos, :integer
    field :chips, :float
    field :hole_cards, :string
  end

  defp all_fields() do
    __MODULE__.__schema__(:fields)
  end

  def changeset(player \\ %__MODULE__{}, attrs) do
    player
    |> cast(attrs, all_fields())
    # https://elixirforum.com/t/confusion-about-cast-assoc-and-cast-fk/3526/11
    # 外键game_id是后边插入DB的时候, 从DB得来的, 这里验证永远会缺失
    |> validate_required(all_fields() -- [:game_id])
    |> unique_constraint([:game_id, :username])
  end
end
