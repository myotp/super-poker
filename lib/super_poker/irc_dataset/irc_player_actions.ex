defmodule SuperPoker.IrcDataset.IrcPlayerActions do
  use Ecto.Schema
  import Ecto.Changeset

  alias SuperPoker.Repo
  alias SuperPoker.IrcDataset.PlayerActions

  @optional_fields [:flop, :turn, :river, :hole_cards]

  @primary_key false
  schema "irc_player_actions" do
    # 不自动生成id主键，用username+game_id做复合主键
    field :username, :string, primary_key: true
    field :game_id, :integer, primary_key: true

    field :num_players, :integer
    field :pos, :integer
    # Actions for 4 streets
    field :preflop, :string
    field :flop, :string
    field :turn, :string
    field :river, :string
    # Balance
    field :bankroll, :integer
    field :total_bet, :integer
    field :winnings, :integer
    field :hole_cards, :string
  end

  defp all_fields() do
    __MODULE__.__schema__(:fields)
  end

  def save_player_actions(%PlayerActions{} = player_actions) do
    player_actions
    |> Map.from_struct()
    |> changeset()
    # upsert如果冲突则简单忽略即可, 后续如果修改整体数据, 删除重新导入即可
    |> Repo.insert(conflict_target: [:username, :game_id], on_conflict: :nothing)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, all_fields())
    |> validate_required(all_fields() -- @optional_fields)
    |> unique_constraint([:username, :game_id], name: :irc_player_actions_pkey)
  end
end
