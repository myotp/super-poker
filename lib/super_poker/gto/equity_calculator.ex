# 这里，根据几本书上的概念，正式走起equity_calculator模块这个概念
# 经过前边的探索，基本明确了，实际过程中就用10万轮来进行模拟
# 因此这里模拟多少轮就固定下来了
defmodule SuperPoker.Gto.EquityCalculator do
  @moduledoc """
  计算普通equity
  """

  alias SuperPoker.Core.{Deck, Hand}
  alias SuperPoker.Gto.{Range, Combo}

  @rounds 100_000
  @sample_rate 0.01

  # ============== 对外可使用的API接口 ===============
  # opts: [rounds: 100_000,
  #        strong_seed: false
  #        sample_print: :lose,
  #        sample_rate: 0.02]
  def preflop_hand_vs_hand(hand1, hand2, opts \\ []) do
    hand_vs_other(hand1, {:hand, hand2}, [], opts)
  end

  def preflop_hand_vs_range(hand, range, opts \\ []) do
    hand_vs_other(hand, {:range, range}, [], opts)
  end

  def preflop_hand_vs_atc(hand1, opts \\ []) do
    hand_vs_other(hand1, :atc, [], opts)
  end

  # 最终实现主入口
  defp hand_vs_other(hero_hand, villain_hand_or_range, _community_cards, opts) do
    h_cards = parse_hand(hero_hand)

    villain_hand_generator = hand_generator(villain_hand_or_range, h_cards)

    1..rounds(opts)
    |> Enum.reduce(%{win: 0, tie: 0, lose: 0}, fn _, acc ->
      maybe_strong_set_random_seed(Keyword.get(opts, :strong_seed, false))
      v_cards = villain_hand_generator.()

      {game_result, community_cards} = run_one_round_random_hand_vs_hand(h_cards, v_cards)

      case Keyword.get(opts, :sample_print) do
        ^game_result ->
          if :rand.uniform() < Keyword.get(opts, :sample_rate, @sample_rate) do
            IO.puts(
              "#{inspect(h_cards)} #{game_result} #{inspect(Hand.sort(v_cards))} #{inspect(Hand.sort(community_cards))}"
            )
          end

        _ ->
          :ok
      end

      Map.update!(acc, game_result, fn x -> x + 1 end)
    end)
    |> equity_from_win_tie_lose_result()
  end

  defp hand_generator({:hand, hand}, _) do
    hand = parse_hand(hand)
    fn -> hand end
  end

  defp hand_generator({:range, range}, blocker_cards) do
    hands =
      range
      |> Range.from_string()
      |> Combo.remove_blocker_combos(blocker_cards)

    fn -> Enum.random(hands) end
  end

  defp hand_generator(:atc, hero_cards) do
    deck =
      Deck.seq_deck52()
      |> exclude_cards(hero_cards)

    fn ->
      deck
      |> Deck.shuffle()
      |> Deck.top_n_cards(2)
    end
  end

  defp run_one_round_random_hand_vs_hand(hand1, hand2) do
    community_cards =
      Deck.random_deck()
      |> exclude_cards([hand1, hand2])
      |> Deck.top_n_cards(5)

    {Hand.compare(hand1, hand2, community_cards), community_cards}
  end

  defp equity_from_win_tie_lose_result(%{win: win, tie: tie, lose: lose}) do
    total = win + tie + lose
    {(win + tie / 2) / total * 100, (tie / 2 + lose) / total * 100}
  end

  # 重构代码，更底层的--或者Enum.split被用新的领域语言函数封装，可读性更好
  defp exclude_cards(cards, cards_to_exclude) do
    cards -- List.flatten(cards_to_exclude)
  end

  defp maybe_strong_set_random_seed(false), do: :ok

  defp maybe_strong_set_random_seed(true) do
    {a, b, c} = :os.timestamp()
    str = "#{a}-#{b}-#{c}-#{:rand.uniform()}"
    <<random_seed_number::little-size(256)>> = :crypto.hash(:sha256, str)
    :rand.seed(:default, random_seed_number)
  end

  defp parse_hand(hand) when is_list(hand), do: hand
  defp parse_hand(str) when is_binary(str), do: Hand.from_string(str)

  defp rounds(opts), do: Keyword.get(opts, :rounds, default_rounds())

  defp default_rounds(),
    do: Application.get_env(:super_poker, :equity_random_rounds, @rounds)
end
