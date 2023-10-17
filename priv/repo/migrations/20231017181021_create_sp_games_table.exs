defmodule SuperPoker.Repo.Migrations.CreateSpGamesTable do
  use Ecto.Migration

  def change do
    create table(:sp_games) do
      add :start_time, :naive_datetime, null: false
      add :button_pos, :integer, null: false
      add :sb_amount, :float, null: false
      add :bb_amount, :float, null: false
      add :community_cards, :text
    end

    # 因为套用PokerStars的模版, 尽量选一个大一点的数值
    execute "ALTER SEQUENCE sp_games_id_seq RESTART WITH 246357389501;"
  end
end
