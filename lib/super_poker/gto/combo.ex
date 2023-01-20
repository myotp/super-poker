defmodule SuperPoker.Gto.Combo do
  alias SuperPoker.Core.Hand

  def remove_blocker_combos(hands, blocker_cards) do
    hands
    |> Enum.reject(fn hand ->
      Hand.with_same_card?(hand, blocker_cards)
    end)
  end
end
