defmodule SuperPoker.Repo.Migrations.CreateSpGamePlayersTable do
  use Ecto.Migration

  def change do
    create table(:sp_game_players) do
      add :game_id, references(:sp_games)
      add :username, :text, null: false
      add :chips, :float, null: false
      add :hole_cards, :text, null: false
    end
  end
end
