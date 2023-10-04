defmodule SuperPoker.PlayerNotify.PlayerNotifierApi do
  @callback notify_players_info(any(), any()) :: :ok
end
