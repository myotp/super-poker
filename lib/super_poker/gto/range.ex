defmodule SuperPoker.Gto.Range do
  alias SuperPoker.Core.{Card, Hand}

  def from_string(str) do
    str
    |> String.split("/")
    |> Enum.map(&parse_range/1)
    |> Enum.map(&generate_hands/1)
    |> Enum.concat()
    |> remove_duplicate()
  end

  defp parse_range(str) do
    case String.codepoints(str) do
      [rank, rank, "+"] ->
        {:pair_from, Card.string_to_rank(rank)}
    end
  end

  defp generate_hands({:pair_from, rank}) do
    rank..Card.ace_rank()
    |> Enum.map(&generate_pair_with_rank/1)
    |> Enum.concat()
  end

  defp generate_pair_with_rank(rank) do
    Enum.reduce(Card.all_suits(), [], fn suit, acc ->
      me = Card.new(rank, suit)
      other_suits = Card.all_suits() -- [suit]

      hands =
        for suit <- other_suits do
          Hand.sort([me, Card.new(rank, suit)])
        end

      acc ++ hands
    end)
  end

  defp remove_duplicate(hands) do
    hands
    |> MapSet.new()
    |> Enum.to_list()
  end
end
