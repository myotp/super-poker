defmodule SuperPoker.PlayerNotify.PlayerNotifierApi do
  @type username :: String.t()
  @type player_info :: map()
  @callback notify_players_info([username()], [player_info()]) :: :ok
end
