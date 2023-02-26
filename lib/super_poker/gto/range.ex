defmodule SuperPoker.Gto.Range do
  defmodule MyApp.Web.Search do
    @moduledoc """
    这个模块负责解析range表达式诸如TT+ AKs等
    """
  end

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

      [high, low | opts] ->
        {:high_low, Card.string_to_rank(high), Card.string_to_rank(low),
         parse_high_low_opts(opts)}
    end
  end

  defp parse_high_low_opts(opts) do
    default_opts = %{from: false, suit: :suit_and_offsuit}

    Enum.reduce(opts, default_opts, fn
      "s", acc -> Map.put(acc, :suit, :suit)
      "o", acc -> Map.put(acc, :suit, :offsuit)
      "+", acc -> Map.put(acc, :from, true)
    end)
  end

  # AA
  defp generate_hands({:pair_from, rank}) do
    rank..Card.ace_rank()
    |> Enum.map(&generate_pair_with_rank/1)
    |> Enum.concat()
  end

  # AK+
  defp generate_hands({:high_low, high, low, %{from: true, suit: suit_opts}}) do
    high..Card.ace_rank()
    |> Enum.map(fn h -> do_generate_high_and_low_from(h, low, suit_opts) end)
    |> Enum.concat()
  end

  # AK
  defp generate_hands({:high_low, high, low, %{from: false, suit: suit_opts}}) do
    do_generate_high_low_combos(high, low, suit_opts)
  end

  defp do_generate_high_and_low_from(high, low0, suit_opts) do
    for low <- low0..(high - 1) do
      do_generate_high_low_combos(high, low, suit_opts)
    end
    |> Enum.concat()
  end

  # 最终产生X-Y是否花色组合的工作函数
  defp do_generate_high_low_combos(high, low, :suit_and_offsuit) when high > low do
    for high_card <- Card.all_cards_with_rank(high) do
      for low_card <- Card.all_cards_with_rank(low) do
        [high_card, low_card]
      end
    end
    |> Enum.concat()
  end

  defp do_generate_high_low_combos(high, low, :suit) when high > low do
    for suit <- Card.all_suits() do
      [Card.new(high, suit), Card.new(low, suit)]
    end
  end

  defp do_generate_high_low_combos(high, low, :offsuit) when high > low do
    do_generate_high_low_combos(high, low, :suit_and_offsuit) --
      do_generate_high_low_combos(high, low, :suit)
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
