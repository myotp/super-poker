defmodule SuperPoker.Player do
  alias SuperPoker.Player.PlayerServer

  def start_player(username) do
    PlayerServer.start_player(username)
  end

  def join_table(username, table_id, buyin) do
    PlayerServer.join_table(username, table_id, buyin)
  end

  def start_game(username) do
    PlayerServer.start_game(username)
  end

  def player_action(username, action) do
    PlayerServer.player_action(username, action)
  end
end
