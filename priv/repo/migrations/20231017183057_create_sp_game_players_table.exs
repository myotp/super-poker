defmodule SuperPoker.Repo.Migrations.CreateSpGamePlayersTable do
  use Ecto.Migration

  def change do
    create table(:sp_game_players, primary_key: false) do
      add :game_id, references(:sp_games), primary_key: true
      add :username, :text, null: false, primary_key: true
      add :pos, :integer, null: false
      add :chips, :float, null: false
      add :hole_cards, :text, null: false
    end
  end
end
