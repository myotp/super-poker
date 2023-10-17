defmodule SuperPoker.HandHistory.PokerstarsExporter do
  alias SuperPoker.HandHistory.HandHistory

  def to_string(%HandHistory{} = hh, hero) do
    [
      table_metadata(hh),
      players_info(hh),
      blinds_info(hh),
      hole_cards_info(hh, hero),
      actions(hh),
      summary(hh)
    ]
    |> Enum.join("\n")
  end

  def table_metadata(%HandHistory{} = hh) do
    """
    #{hh.format} Hand ##{hh.game_id}:  #{hh.poker_type} ($#{to_usd(hh.sb_amount)}/$#{to_usd(hh.bb_amount)} USD) - #{to_timestamp(hh.start_time)} ET
    Table '#{hh.table_name}' #{hh.table_type} Seat ##{hh.button_pos} is the button
    """
    |> String.trim_trailing("\n")
  end

  def players_info(%HandHistory{} = hh) do
    hh.players
    |> Enum.to_list()
    |> Enum.sort_by(fn {pos, _player} -> pos end)
    |> Enum.map(fn {pos, player} ->
      "Seat #{pos}: #{player.username} ($#{to_usd(player.chips)} in chips)"
    end)
    |> Enum.join("\n")
  end

  def blinds_info(%HandHistory{blinds: blinds}) do
    [{u1, sb}, {u2, bb}] =
      blinds
      |> Enum.to_list()
      |> Enum.sort_by(fn {_username, amount} -> amount end)

    """
    #{u1}: posts small blind $#{to_usd(sb)}
    #{u2}: posts big blind $#{to_usd(bb)}
    """
    |> String.trim_trailing("\n")
  end

  def hole_cards_info(%HandHistory{hole_cards: hole_cards}, hero) do
    """
    *** HOLE CARDS ***
    Dealt to #{hero} [#{capitalize_card_string(hole_cards[hero])}]
    """
    |> String.trim_trailing("\n")
  end

  def actions(%HandHistory{actions: actions}) do
    actions
    |> Enum.map(&action_to_string/1)
    |> Enum.join("\n")
  end

  def summary(hh) do
    """
    *** SUMMARY ***
    Board [#{capitalize_card_string(hh.community_cards)}]
    """
    |> String.trim_trailing("\n")
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

  defp to_timestamp(naive_datetime) do
    naive_datetime
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.to_iso8601()
    |> String.replace("T", " ")
    |> String.replace("-", "/")
  end

  defp to_usd(amount) when is_integer(amount) do
    Integer.to_string(amount)
  end

  defp to_usd(amount) when is_float(amount) do
    float_to_currency_str(amount)
  end

  defp float_to_currency_str(amount) do
    :erlang.float_to_binary(amount, decimals: 2)
  end
end
