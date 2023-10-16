defmodule SuperPoker.IrcDataset.Table do
  defstruct [
    :game_id,
    :blind,
    :pot_after_preflop,
    :pot_after_flop,
    :pot_after_turn,
    :pot_after_river,
    :community_cards
  ]

  def parse(str) do
    case String.split(str, " ", trim: true) do
      [game_id, blind, _seq, _num_of_players, p1, p2, p3, p4 | cards] ->
        %__MODULE__{
          game_id: game_id |> String.to_integer(),
          blind: blind |> String.to_integer(),
          pot_after_preflop: p1 |> extract_pot(),
          pot_after_flop: p2 |> extract_pot(),
          pot_after_turn: p3 |> extract_pot(),
          pot_after_river: p4 |> extract_pot(),
          community_cards: parse_cards(cards)
        }

      _ ->
        IO.puts("HELP! #{str}")
        nil
    end
  end

  defp parse_cards(cards) do
    cards
    |> Enum.join(" ")
    |> String.upcase()
  end

  defp extract_pot(pot_str) do
    [_num_players_left, pot] = String.split(pot_str, "/")
    String.to_integer(pot)
  end
end
