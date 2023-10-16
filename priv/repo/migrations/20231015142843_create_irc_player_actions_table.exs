defmodule SuperPoker.Repo.Migrations.CreateIrcPlayerActionsTable do
  use Ecto.Migration

  def change do
    create table(:irc_player_actions, primary_key: false) do
      # 无需id做主键, username+game_id即可
      add :username, :text, null: false, primary_key: true
      add :game_id, :bigint, null: false, primary_key: true

      add :num_players, :integer, null: false
      add :pos, :integer, null: false

      # 只有preflop必须有操作
      add :preflop, :text, null: false
      add :flop, :text
      add :turn, :text
      add :river, :text

      add :bankroll, :integer, null: false
      add :total_bet, :integer, null: false
      add :winnings, :integer, null: false

      # 最终不一定有手牌记录
      add :hole_cards, :text
    end

    #    create unique_index(:irc_player_actions, [:username, :game_id])
    create index(:irc_player_actions, [:username])
    create index(:irc_player_actions, [:game_id])
  end
end
