defmodule SuperPoker.PlayerNotify.PlayerNotifierBehaviour do
  @type username :: String.t()
  @type player_info :: map()
  @type cards :: list()

  @callback notify_players_info([username()], [player_info()]) :: :ok
  @callback notify_bets_info([username()], map()) :: :ok
  @callback deal_hole_cards(username(), cards()) :: :ok
  @callback notify_player_todo_actions([username()], username(), list()) :: :ok
  @callback deal_community_cards([username()], street :: atom(), cards()) :: :ok
end
