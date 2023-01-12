defmodule SuperPoker.Core.DeckTest do
  use ExUnit.Case
  doctest SuperPoker.Core.Deck
  alias SuperPoker.Core.Deck

  test "Deck from Ace to 2" do
    deck = Deck.seq_deck52()
    assert Enum.count(deck) == 52

    [ace1, ace2, ace3, ace4, king1 | _] = deck
    assert ace1.rank == 14
    assert ace2.rank == 14
    assert ace3.rank == 14
    assert ace4.rank == 14
    assert king1.rank == 13
  end
end
