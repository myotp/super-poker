defmodule SuperPoker.Repo.Migrations.CreateIrcTablesTable do
  use Ecto.Migration

  def change do
    create table(:irc_tables, primary_key: false) do
      # 无需id做主键game_id即可
      add :game_id, :bigint, null: false, primary_key: true
      add :blind, :integer, null: false
      add :pot_after_preflop, :integer, null: false
      add :pot_after_flop, :integer, null: false
      add :pot_after_turn, :integer, null: false
      add :pot_after_river, :integer, null: false
      add :community_cards, :text, null: false
    end
  end
end
