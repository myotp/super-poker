defmodule SuperPoker.Bot.BotBehaviour do
  @type table :: map()
  @type action :: :fold | :check | {:call, number()}
  @type cards :: list(any())

  # TODO: behaviour type
  @type bot :: any()

  @callback new(String.t(), any()) :: bot()
  @callback random_username() :: String.t()
  @callback make_decision(bot()) :: action()
  @callback deal_hole_cards(bot(), cards()) :: bot()
  @callback deal_community_cards(bot(), String.t(), cards()) :: bot()
  @callback update_todo_actions(bot(), tuple()) :: bot()
  @callback update_bets(bot(), any()) :: bot()
end
