# 提供API访问封装
defmodule SuperPoker.Table do
  alias SuperPoker.GameServer.HeadsupTableServer

  def join_table(table_id, username) do
    HeadsupTableServer.join_table(table_id, username)
  end
end
