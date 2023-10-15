defmodule SuperPoker.IrcDataset.IrcPlayerActions do
  use Ecto.Schema
  import Ecto.Changeset

  alias SuperPoker.Repo
  alias SuperPoker.IrcDataset.PlayerActions

  @required_fields [
    :username,
    :game_id,
    :num_players,
    :pos,
    :preflop,
    :bankroll,
    :total_bet,
    :winnings
  ]
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

  def save_player_actions(%PlayerActions{} = player_actions) do
    player_actions
    |> Map.from_struct()
    |> changeset()
    |> Repo.insert()
  end

  def changeset(irc_player_actions \\ %__MODULE__{}, attrs) do
    irc_player_actions
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:username, :game_id], name: :irc_player_actions_pkey)
  end
end
