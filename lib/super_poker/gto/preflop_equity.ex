defmodule SuperPoker.Gto.PreflopEquity do
  alias SuperPoker.Core.{Card, Hand, Deck}
  @rounds 100

  def ace_king_offsuit_equity(rounds \\ @rounds) do
    ace = Card.new(14, :hearts)
    king = Card.new(13, :diamonds)
    hole_cards_equity([ace, king], rounds)
  end

  def ace_king_suit_equity(rounds \\ @rounds) do
    ace = Card.new(14, :hearts)
    king = Card.new(13, :hearts)
    hole_cards_equity([ace, king], rounds)
  end

  def hole_cards_equity([_, _] = p1_cards, rounds) do
    1..rounds
    |> Enum.reduce(%{}, fn _, acc ->
      game_result = run_two_cards_vs_any_two_cards(p1_cards)
      Map.update(acc, game_result, 1, fn x -> x + 1 end)
    end)
  end

  defp run_two_cards_vs_any_two_cards([_, _] = p1_cards) do
    deck = Deck.random_deck() -- p1_cards
    {p2_cards, deck} = Enum.split(deck, 2)
    {community_cards, _} = Enum.split(deck, 5)
    Hand.compare(p1_cards, p2_cards, community_cards)
  end
end
