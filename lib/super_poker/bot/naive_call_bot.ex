defmodule SuperPoker.Bot.NaiveCallBot do
  @behaviour SuperPoker.Bot.BotBehaviour

  @impl SuperPoker.Bot.BotBehaviour
  def make_decision(table) do
    case table.amount_to_call do
      0 -> :check
      _ -> :call
    end
  end
end
