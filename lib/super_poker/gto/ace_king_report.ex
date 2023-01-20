defmodule SuperPoker.Gto.AceKingReport do
  alias SuperPoker.Gto.EquityCalculator

  def report_all(rounds \\ 10_000) do
    IO.puts("=== 执行AK计算采样#{rounds} ===")
    report_preflop_vs_range_equity(rounds)
  end

  def report_preflop_vs_range_equity(rounds) do
    IO.puts("=== 来看AK对范围翻前胜率 ===")

    {ako_vs_55_equity, _} =
      EquityCalculator.preflop_hand_vs_hand("AS KH", "5D 5C", rounds: rounds)

    IO.puts("AK不同花对55翻前胜率书上为45，实际为#{ako_vs_55_equity}")

    {ako_vs_jj_plus_ak_range_quity, _} =
      EquityCalculator.preflop_hand_vs_range("AS KH", "JJ+/AK", rounds: rounds)

    IO.puts("AK不同花对JJ+/AK范围翻前胜率书上为40，实际为#{ako_vs_jj_plus_ak_range_quity}")
  end
end
