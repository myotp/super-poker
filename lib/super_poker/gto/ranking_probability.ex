defmodule SuperPoker.Gto.RankingProbability do
  alias SuperPoker.Core.{Deck, Ranking}

  def hand_types(rounds) do
    type_count =
      Ranking.types()
      |> Enum.zip(Stream.cycle([0]))
      |> Enum.into(%{})

    Enum.reduce(1..rounds, type_count, fn _, acc ->
      ranking =
        Deck.random_deck()
        |> Deck.top_n_cards(7)
        |> Ranking.run()

      Map.update!(acc, ranking.type, fn x -> x + 1 end)
    end)
  end
end
