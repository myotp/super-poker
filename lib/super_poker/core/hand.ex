defmodule SuperPoker.Core.Hand do
  @moduledoc """
  扑克游戏当中核心一手牌Hand表示

  这里，hand可以表示输入的一手牌(7张)挑出来五张最大的牌
  也可以表示选完五张之后输出的一手牌(5张)，本身就是一个[%Card{}]的简单封装而已
  内部的表示，根据算法，决定数据结构，用数字来替代牌，方便做比较

  这里，不考虑手牌公共牌的区别，那些规则由上一层负责
  """

  alias SuperPoker.Core.Card
  alias SuperPoker.Core.Ranking

  # FIXME: 是否需要改为struct，其中某一个属性是cards?
  @type t :: [Card.t()]

  def from_string(str) do
    str
    |> String.split(" ")
    |> Enum.map(&Card.from_string/1)
  end

  def compare(p1_cards, p2_cards, community_cards) do
    r1 = Ranking.run(p1_cards ++ community_cards)
    r2 = Ranking.run(p2_cards ++ community_cards)

    case compare_ranking_type(r1.type, r2.type) do
      :gt ->
        :win

      :lt ->
        :lose

      :eq ->
        compare_in_same_type(r1.order_key, r2.order_key)
    end
  end

  # 这里最简单的同类型比较，但是四条的时候，比如看手里牌情况没有细致处理暂时
  defp compare_in_same_type([], []), do: :tie
  defp compare_in_same_type([c1 | _], [c2 | _]) when c1 > c2, do: :win
  defp compare_in_same_type([c1 | _], [c2 | _]) when c1 < c2, do: :lose

  defp compare_in_same_type([_ | rest1], [_ | rest2]), do: compare_in_same_type(rest1, rest2)

  defp compare_ranking_type(type1, type2) do
    compare_num(ranking_to_score(type1), ranking_to_score(type2))
  end

  defp ranking_to_score(:royal_flush), do: 100
  defp ranking_to_score(:straight_flush), do: 90
  defp ranking_to_score(:four_of_a_kind), do: 80
  defp ranking_to_score(:full_house), do: 70
  defp ranking_to_score(:flush), do: 60
  defp ranking_to_score(:straight), do: 50
  defp ranking_to_score(:three_of_a_kind), do: 40
  defp ranking_to_score(:two_pairs), do: 30
  defp ranking_to_score(:pair), do: 20
  defp ranking_to_score(:high_card), do: 10

  defp compare_num(a, b) do
    cond do
      a < b -> :lt
      a > b -> :gt
      true -> :eq
    end
  end

  def sort(cards) do
    Enum.sort_by(cards, &Card.card_to_points/1, :desc)
  end
end
