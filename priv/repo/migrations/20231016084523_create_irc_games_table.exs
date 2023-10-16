defmodule SuperPoker.Repo.Migrations.CreateIrcGamesTable do
  use Ecto.Migration

  def change do
    create table(:irc_games) do
      add :game_id, :integer, null: false
      add :num_players, :integer, null: false
      add :players, {:array, :text}, null: false
    end

    create unique_index(:irc_games, [:game_id])
  end
end
