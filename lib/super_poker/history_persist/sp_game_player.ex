defmodule SuperPoker.HistoryPersist.SpGamePlayer do
  use Ecto.Schema

  alias SuperPoker.HistoryPersist.SpGame

  schema "sp_game_players" do
    field :username, :string
    field :chips, :float
    field :hole_cards, :string
    belongs_to :game, SpGame, foreign_key: :game_id
  end
end
