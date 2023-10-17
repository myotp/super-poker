defmodule SuperPoker.HandHistory.PokerstarsExporter do
  alias SuperPoker.HandHistory.HandHistory

  # TODO: 用上模版LEEx还是HEEx
  def to_string(%HandHistory{}) do
    """
    SuperPoker Hand #12345:  Hold'em No Limit ($2.50/$5.00 USD) - 1999-12-31 23:59:59
    Table 'Rigel' 6-max Seat #4 is the button
    Seat 1: Anna ($1091.61 in chips)
    Seat 2: Bob ($581.64 in chips)
    """
  end

  def action_to_string({:deal, :flop, cards}) do
    "*** FLOP *** [#{capitalize_card_string(cards)}]"
  end

  def action_to_string({:deal, :turn, cards}) do
    [c1, c2, c3, turn] =
      cards
      |> capitalize_card_string()
      |> String.split(" ")

    flop = Enum.join([c1, c2, c3], " ")
    "*** TURN *** [#{flop}] [#{turn}]"
  end

  def action_to_string({:deal, :river, cards}) do
    [c1, c2, c3, c4, river] =
      cards
      |> capitalize_card_string()
      |> String.split(" ")

    flop_and_turn = Enum.join([c1, c2, c3, c4], " ")
    "*** RIVER *** [#{flop_and_turn}] [#{river}]"
  end

  def action_to_string({:player, username, player_action}) do
    "#{username}: #{player_action_to_string(player_action)}"
  end

  defp capitalize_card_string(cards) do
    cards
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp player_action_to_string(:check), do: "checks"

  defp player_action_to_string({:call, amount}) do
    "calls $#{float_to_currency_str(amount)}"
  end

  defp float_to_currency_str(amount) do
    :erlang.float_to_binary(amount, decimals: 2)
  end
end
