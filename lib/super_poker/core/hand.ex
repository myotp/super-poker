defmodule SuperPoker.Core.Hand do
  @moduledoc """
  扑克游戏当中核心一手牌Hand表示

  这里，hand可以表示输入的一手牌(7张)挑出来五张最大的牌
  也可以表示选完五张之后输出的一手牌(5张)，本身就是一个[%Card{}]的简单封装而已
  内部的表示，根据算法，决定数据结构，用数字来替代牌，方便做比较

  这里，不考虑手牌公共牌的区别，那些规则由上一层负责
  """

  alias SuperPoker.Core.Card

  # FIXME: 是否需要改为struct，其中某一个属性是cards?
  @type t :: [Card.t()]

  def new(str) do
    str
    |> String.split(" ")
    |> Enum.map(&Card.from_string/1)
  end

  # FIXME: 这里，后来再看这里代码，觉得很诡异，诡异之处就在于到底想干嘛，后来想想，是为了说ranking预备的
  # 但是，作为API本身，完全没意义，所以，这个API完全鸡肋且不应该在这里
  @spec get_one_card_by_rank(Hand.t(), Card.rank()) :: Card.t() | nil
  def get_one_card_by_rank(hand, rank) do
    Enum.find(hand, fn card -> card.rank == rank end)
  end

  @spec get_hand_by_ranks(Hand.t(), [Card.rank()]) :: Hand.t()
  def get_hand_by_ranks(hand, ranks) do
    Enum.map(ranks, fn rank -> get_one_card_by_rank(hand, rank) end)
  end
end
