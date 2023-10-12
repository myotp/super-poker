# 提供API访问封装
defmodule SuperPoker.Table do
  alias SuperPoker.GameServer.HeadsupTableServer

  def join_table(table_id, username) do
    HeadsupTableServer.join_table(table_id, username)
  end

  def leave_table(table_id, username) do
    HeadsupTableServer.leave_table(table_id, username)
  end

  def start_game(table_id, username) do
    HeadsupTableServer.start_game(table_id, username)
  end

  def player_action_done(table_id, username, action) do
    HeadsupTableServer.player_action_done(table_id, username, action)
  end
end
