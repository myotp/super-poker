defmodule SuperPoker.Core.Card do
  @moduledoc """
  扑克游戏当中核心纸牌Card表示

  ## 单一纸牌的表示方法
   * 内部表示法，点数rank用数字2-14表示，suit为atom比如♥️A表示为 %Card{rank: 14, suit: :hearts}
   * 一种表示法为字符串，比如♥️A表示为"AH"这种表示法用来一般网络传输序列化以及一般性输入
   * 一种emoji表示法，为带有实际♠️♥️♣️♦️的表示法，用来实现自己命令行程序的时候，输出比较好看，比如♥️K
  """
  alias __MODULE__

  @type rank :: integer()
  @type suit :: :spades | :hearts | :clubs | :diamonds
  @type t :: %__MODULE__{
          rank: integer(),
          suit: suit()
        }
  defstruct [:rank, :suit]

  @all_suits [:spades, :hearts, :clubs, :diamonds]
  def all_suits(), do: @all_suits

  def all_ranks(), do: Enum.to_list(2..14)

  def from_string(str) do
    [rank, suit] = String.codepoints(str)
    new(string_to_rank(rank), ascii_string_to_suit(suit))
  end

  # FIXME: 这里，不确定是否对外需要暴露new/2，毕竟14对外部没有什么意义
  @spec new(rank(), suit()) :: Card.t()
  def new(rank, suit)
      when suit in @all_suits and rank in 2..14 do
    %Card{rank: rank, suit: suit}
  end

  # 常规的比如TS, AD, 3C等表示，一般的网络表示
  def to_string(%Card{suit: s, rank: r}) do
    rank_to_string(r) <> suit_to_ascii_string(s)
  end

  # 图形化显示成♠️♥️♣️之类的
  def to_emoji_string(%Card{suit: s, rank: r}) do
    suit_to_emoji_string(s) <> " " <> rank_to_emoji_string(r)
  end

  defp suit_to_ascii_string(:spades), do: "S"
  defp suit_to_ascii_string(:hearts), do: "H"
  defp suit_to_ascii_string(:clubs), do: "C"
  defp suit_to_ascii_string(:diamonds), do: "D"

  defp ascii_string_to_suit("S"), do: :spades
  defp ascii_string_to_suit("H"), do: :hearts
  defp ascii_string_to_suit("C"), do: :clubs
  defp ascii_string_to_suit("D"), do: :diamonds

  defp suit_to_emoji_string(:spades), do: "♠️"
  defp suit_to_emoji_string(:hearts), do: "♥️"
  defp suit_to_emoji_string(:clubs), do: "♣️"
  defp suit_to_emoji_string(:diamonds), do: "♦️"

  defp rank_to_emoji_string(10), do: "10"
  defp rank_to_emoji_string(r), do: rank_to_string(r)

  defp rank_to_string(10), do: "T"
  defp rank_to_string(11), do: "J"
  defp rank_to_string(12), do: "Q"
  defp rank_to_string(13), do: "K"
  defp rank_to_string(14), do: "A"
  defp rank_to_string(num), do: Integer.to_string(num)

  def string_to_rank("T"), do: 10
  def string_to_rank("J"), do: 11
  def string_to_rank("Q"), do: 12
  def string_to_rank("K"), do: 13
  def string_to_rank("A"), do: 14
  def string_to_rank(s), do: String.to_integer(s)

  def card_to_points(%Card{rank: rank, suit: suit}) do
    rank * 4 + suit_to_points(suit)
  end

  defp suit_to_points(:spades), do: 3
  defp suit_to_points(:hearts), do: 2
  defp suit_to_points(:clubs), do: 1
  defp suit_to_points(:diamonds), do: 0

  def ace_rank(), do: 14
end

# 这里一个Inspect类似Python的__repr__函数，一个String.Chars类似__str__函数
# 这里，可能最正统的做法，就是类似Python的效果，一个是显示构建过程的，另一个就是输出看的
# 利用Inspect协议，用unicode的♠♥♣♦等内容改造card的输出
defimpl Inspect, for: SuperPoker.Core.Card do
  # 这里之后，再具体看细致的opts的处理方法
  def inspect(card, _opts) do
    SuperPoker.Core.Card.to_emoji_string(card)
  end
end

defimpl String.Chars, for: SuperPoker.Core.Card do
  def to_string(card) do
    SuperPoker.Core.Card.to_string(card)
  end
end
