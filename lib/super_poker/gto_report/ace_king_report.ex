defmodule SuperPoker.GtoReport.AceKingReport do
  alias SuperPoker.Gto.EquityCalculator

  def report_all(rounds \\ 10_000) do
    IO.puts("=== 执行AK计算采样#{rounds} ===")
    report_rock_paper_scissors(rounds)
    # report_preflop_vs_other_equity(rounds)
  end

  def report_rock_paper_scissors(rounds) do
    IO.puts("先看石头剪刀布原理")

    # AKo, T9s, 55之间的相互制衡
    {ak_equity, _} = EquityCalculator.preflop_hand_vs_hand("AC KH", "5D 5C", ounds: rounds)
    IO.puts("AKo对55，书上说AK胜率为45，实际为#{ak_equity}")
    {ak_equity, _} = EquityCalculator.preflop_hand_vs_hand("AC KH", "TC 9C", ounds: rounds)
    IO.puts("AKo对T9同花，书上说AK胜率为59，实际为#{ak_equity}")
    {ww_equity, _} = EquityCalculator.preflop_hand_vs_hand("5D 5C", "TC 9C", ounds: rounds)
    IO.puts("55对T9同花，书上说55胜率为48，实际为#{ww_equity}")

    # AKo碾压Axo，大对碾压小对，但是AKo面对大对表现还凑合
    {ak_equity, _} = EquityCalculator.preflop_hand_vs_hand("AC KH", "AH QC", ounds: rounds)
    IO.puts("AKo对AQ，书上说AK胜率为75，实际为#{ak_equity}")
    {ak_equity, _} = EquityCalculator.preflop_hand_vs_hand("AC KH", "JD JC", ounds: rounds)
    IO.puts("AKo对JJ，书上说AK胜率为43，实际为#{ak_equity}")
    {jj_equity, _} = EquityCalculator.preflop_hand_vs_hand("JD JC", "5D 5C", ounds: rounds)
    IO.puts("JJ对55，书上说JJ胜率为81，实际为#{jj_equity}")
    {aq_equity, _} = EquityCalculator.preflop_hand_vs_hand("AH QC", "5D 5C", ounds: rounds)
    IO.puts("AQo对55，书上说AQ胜率为45，实际为#{aq_equity}")

    # 对ATC来评估，因为随机对手，尽量扩大样本数量
    {ak_equity, _} = EquityCalculator.preflop_hand_vs_atc("AC KH", ounds: rounds * 5)
    IO.puts("AKo对任意两张，书上说AK胜率为65，实际为#{ak_equity}")
    {ww_equity, _} = EquityCalculator.preflop_hand_vs_atc("5D 5C", rounds: rounds * 5)
    IO.puts("55对任意两张，书上说55胜率为60，实际为#{ww_equity}")
    {t9s_equity, _} = EquityCalculator.preflop_hand_vs_atc("TC 9C", rounds: rounds * 5)
    IO.puts("T9s对任意两张，书上说T9s胜率为55，实际为#{t9s_equity}")

    IO.puts("""
    最终结果:
    结论1: 扑克当中类似剪刀石头布原理，没有绝对的大牌，AK不同花压制T9同花，T9同花压制55，而55又能小胜AK不同花
    结论2: AKo强力碾压Axo，大对子强力碾压小对子，而AKo即使面对大对子也还表现凑合，所以一般还是认为AK不错的手牌
    结论3: 从对抗任意两张胜率来看，AK还不错的，所以相对还不错
    结论4: T9s的绝对胜率不高，但是，深筹情况下，同花更有机会赢下底池，equity实现能力更强
    """)
  end

  def report_preflop_vs_other_equity(rounds) do
    IO.puts("=== 来看AK对范围翻前胜率 ===")

    {ako_vs_55_equity, _} =
      EquityCalculator.preflop_hand_vs_hand("AS KH", "5D 5C", rounds: rounds)

    IO.puts("AK不同花对55翻前胜率书上为45，实际为#{ako_vs_55_equity}")

    {ako_vs_jj_plus_ak_range_quity, _} =
      EquityCalculator.preflop_hand_vs_range("AS KH", "JJ+/AK", rounds: rounds)

    IO.puts("AK不同花对JJ+/AK范围翻前胜率书上为40，实际为#{ako_vs_jj_plus_ak_range_quity}")

    {ako_vs_atc_quity, _} = EquityCalculator.preflop_hand_vs_atc("AS KH", rounds: rounds)
    IO.puts("AK不同花对任意两张翻前胜率书上为65，实际为#{ako_vs_atc_quity}")
  end
end
