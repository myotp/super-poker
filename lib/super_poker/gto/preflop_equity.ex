defmodule SuperPoker.Gto.PreflopEquity do
  alias SuperPoker.Core.{Hand, Deck}

  def hole_cards_equity([_, _] = p1_cards, rounds) do
    1..rounds
    |> Enum.reduce(%{win: 0, tie: 0, lose: 0}, fn _, acc ->
      game_result = run_two_cards_vs_any_two_cards(p1_cards)
      Map.update(acc, game_result, nil, fn x -> x + 1 end)
    end)
  end

  # 看指定两手牌的对战胜率
  def hole_cards_vs_equity(p1_cards, p2_cards, rounds) do
    1..rounds
    |> Enum.reduce(%{win: 0, tie: 0, lose: 0}, fn _, acc ->
      game_result = run_a_round_cards_vs_cards(p1_cards, p2_cards)
      Map.update(acc, game_result, nil, fn x -> x + 1 end)
    end)
  end

  defp run_a_round_cards_vs_cards(p1_cards, p2_cards) do
    deck = Deck.random_deck() -- (p1_cards ++ p2_cards)
    {community_cards, _} = Enum.split(deck, 5)
    Hand.compare(p1_cards, p2_cards, community_cards)
  end

  defp run_two_cards_vs_any_two_cards([_, _] = p1_cards) do
    deck = Deck.random_deck() -- p1_cards
    50 = Enum.count(deck)
    {p2_cards, deck} = Enum.split(deck, 2)
    {community_cards, _} = Enum.split(deck, 5)
    Hand.compare(p1_cards, p2_cards, community_cards)
  end
end
