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

  def from_string(str) do
    str
    |> String.split(" ")
    |> Enum.map(&Card.from_string/1)
  end
end
