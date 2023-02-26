defmodule SuperPoker.GtoReport.RankingProbabilityReport do
  @moduledoc """
  统计若干手牌带有公共牌出现某种牌型，比如同花，顺子的概率统计
  """

  alias SuperPoker.Core.Ranking
  alias SuperPoker.Gto.RankingProbability

  def hand_types(rounds \\ 1_000) do
    result = RankingProbability.hand_types(rounds)

    for type <- Ranking.types() do
      IO.puts("#{pad_num(result[type], 10)} #{type}")
    end

    :ok
  end

  defp pad_num(num, n) do
    num
    |> Integer.to_string()
    |> String.pad_leading(n)
  end
end
