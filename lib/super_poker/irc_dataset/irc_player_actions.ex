defmodule SuperPoker.IrcDataset.IrcPlayerActions do
  use Ecto.Schema

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
end
