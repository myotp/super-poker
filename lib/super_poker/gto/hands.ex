defmodule SuperPoker.Gto.Hands do
  def remove_blocker_combos(hands, blocker_cards) do
    hands
    |> Enum.reject(fn hand ->
      has_same_cards?(hand, blocker_cards)
    end)
  end

  defp has_same_cards?(hand1, hand2) do
    s1 = MapSet.new(hand1)
    s2 = MapSet.new(hand2)
    not MapSet.disjoint?(s1, s2)
  end
end
