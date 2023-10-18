defmodule SuperPoker.Repo.Migrations.CreateSpGamePlayerActionsTable do
  use Ecto.Migration

  def change do
    create table(:sp_player_actions) do
      add :game_id, references(:sp_games), null: false, primary_key: true
      add :username, :text, null: false, primary_key: true
      add :preflop, {:array, :map}
      add :flop, {:array, :map}
      add :turn, {:array, :map}
      add :river, {:array, :map}
    end

    create index(:sp_player_actions, [:username])
  end
end
