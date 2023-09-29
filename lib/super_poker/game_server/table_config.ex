defmodule SuperPoker.GameServer.TableConfig do
  defstruct [
    :table_id,
    :max_players,
    :buyin,
    :sb,
    :bb
  ]
end
