defmodule SuperPoker.Core.Deck do
  alias SuperPoker.Core.Card

  def seq_deck52() do
    for rank <- Card.all_ranks() |> Enum.reverse() do
      for suit <- Card.all_suits() do
        Card.new(rank, suit)
      end
    end
    |> Enum.concat()
  end

  def shuffle(deck) do
    naive_shuffle(deck)
  end

  def naive_shuffle(deck) do
    Enum.shuffle(deck)
  end

  def random_deck() do
    seq_deck52()
    |> shuffle()
  end
end
