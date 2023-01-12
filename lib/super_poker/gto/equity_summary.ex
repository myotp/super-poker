# 这个模块，是利用基础的equity计算模块，用来生成一些统计结果的
defmodule SuperPoker.Gto.EquitySummary do
  alias SuperPoker.Core.Hand
  alias SuperPoker.Gto.PreflopEquity

  @sample_rounds [100, 1_000, 10_000, 100_000]
  def preflop_equity_report(s1, s2) do
    h1 = Hand.from_string(s1)
    h2 = Hand.from_string(s2)

    result =
      Enum.map(@sample_rounds, fn n ->
        r = PreflopEquity.hole_cards_vs_equity(h1, h2, n)
        {n, r.win, r.tie, r.lose}
      end)

    pretty_print_result(result)
  end

  def hole_cards_equity_report(s1) do
    h1 = Hand.from_string(s1)

    result =
      Enum.map(@sample_rounds, fn n ->
        r = PreflopEquity.hole_cards_equity(h1, n)
        {n, r.win, r.tie, r.lose}
      end)

    pretty_print_result(result)
  end

  def pretty_print_result(result) do
    IO.puts("""
    | rounds |   win | tie |  lose |
    |--------|-------|-----|-------|
    """)

    for {n, win, tie, lose} <- result do
      IO.puts(["|", p(n, 7), " |", p(win, 6), " |", p(tie, 4), " |", p(lose, 6), " |"])
    end
  end

  defp p(i, n) do
    i
    |> Integer.to_string()
    |> String.pad_leading(n)
  end
end
