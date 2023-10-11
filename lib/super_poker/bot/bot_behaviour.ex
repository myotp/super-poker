defmodule SuperPoker.Bot.BotBehaviour do
  @type table :: map()
  @type action :: :fold | :check | {:call, number()}

  @callback make_decision(table()) :: action()
end
