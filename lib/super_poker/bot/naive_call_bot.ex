defmodule SuperPoker.Bot.NaiveCallBot do
  alias SuperPoker.Bot.BotBehaviour
  alias SuperPoker.Bot.NaiveCallBot, as: Bot
  alias SuperPoker.Bot.NaiveHeadsupTable
  @behaviour BotBehaviour

  defstruct [
    :my_username,
    :oppo_username,
    :table
  ]

  @impl BotBehaviour
  # 根据当前盲注阶段大小盲信息创建bot
  # {:bets_info,
  #    %{:pot => 0,
  #      "anna" => %{chips_left: 490, current_street_bet: 10},
  #      "bot576460752303421177" => %{chips_left: 495, current_street_bet: 5}}}
  def new(my_username, _bets_info) do
    %Bot{
      my_username: my_username,
      table: NaiveHeadsupTable.new(888, 999)
    }
  end

  @impl BotBehaviour
  def make_decision(%Bot{table: table}) do
    case table.amount_to_call do
      0 -> :check
      _ -> :call
    end
  end

  @impl BotBehaviour
  def random_username() do
    num = System.unique_integer() |> abs()
    "NaiveCall#{num}"
  end

  @impl BotBehaviour
  def deal_hole_cards(%Bot{table: table} = bot, hole_cards) do
    table = NaiveHeadsupTable.deal_hole_cards(table, hole_cards)
    %Bot{bot | table: table}
  end

  @impl BotBehaviour
  def deal_community_cards(%Bot{table: table} = bot, _street, community_cards) do
    table = NaiveHeadsupTable.deal_community_cards(table, community_cards)
    %Bot{bot | table: table}
  end

  @impl BotBehaviour
  # 自己
  def update_todo_actions(
        %Bot{table: table, my_username: my_username} = bot,
        {:todo_actions, my_username, actions}
      ) do
    amount_to_call = actions[:call] || 0
    table = NaiveHeadsupTable.update_amount_to_call(table, amount_to_call)
    %Bot{bot | table: table}
  end

  # 对手
  def update_todo_actions(%Bot{} = bot, _) do
    bot
  end

  @impl BotBehaviour
  # TODO: 后续持续更新下注信息
  def update_bets(%Bot{} = bot, _bets_info) do
    bot
  end
end
