# 这里，根据几本书上的概念，正式走起equity_calculator模块这个概念
# 经过前边的探索，基本明确了，实际过程中就用10万轮来进行模拟
# 因此这里模拟多少轮就固定下来了
defmodule SuperPoker.Gto.EquityCalculator do
  @default_sample_rounds 100_000
  alias SuperPoker.Core.{Deck, Hand}

  # ============== 对外可使用的API接口 ===============
  def preflop_hand_vs_hand(hand1, hand2, opts \\ []) do
    hand_vs_hand(hand1, hand2, [], opts)
  end

  # 最终实现主入口
  defp hand_vs_hand(hand1, hand2, _community_cards, _opts) do
    1..sample_rounds()
    |> Enum.reduce(%{win: 0, tie: 0, lose: 0}, fn _, acc ->
      game_result = run_one_round_random_hand_vs_hand(hand1, hand2)
      Map.update!(acc, game_result, fn x -> x + 1 end)
    end)
    |> equity_from_win_tie_lose_result()
  end

  defp run_one_round_random_hand_vs_hand(hand1, hand2) do
    community_cards =
      random_deck()
      |> exclude_cards([hand1, hand2])
      |> take_n_cards_from_deck(5)

    Hand.compare(hand1, hand2, community_cards)
  end

  defp equity_from_win_tie_lose_result(%{win: win, tie: tie, lose: lose}) do
    total = win + tie + lose
    {(win + tie / 2) / total * 100, (tie / 2 + lose) / total * 100}
  end

  # 重构代码，更底层的--或者Enum.split被用新的领域语言函数封装，可读性更好
  defp exclude_cards(cards, cards_to_exclude) do
    cards -- List.flatten(cards_to_exclude)
  end

  defp random_deck() do
    Deck.random_deck()
  end

  defp take_n_cards_from_deck(deck, n) do
    {cards, _} = Enum.split(deck, n)
    cards
  end

  defp sample_rounds(),
    do: Application.get_env(:super_poker, :equity_sample_rounds, @default_sample_rounds)
end
