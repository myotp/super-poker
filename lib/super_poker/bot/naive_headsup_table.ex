defmodule SuperPoker.Bot.NaiveHeadsupTable do
  alias SuperPoker.Bot.NaiveHeadsupTable, as: Table

  @moduledoc """
  这里定义从玩家视角观看的table情况
  优先简单实现, 先定义简单的做法, 实现相关接口, 后续可以在接口维持不变的情况下进行修改内部实现变得更复杂比如

  pot的简化
  这里, 开始实现的时候可以做简化处理, 也就是对手玩家随时下注就"进入"pot
  实际场景中, 玩家下注只放自己门口, 等最终大家都匹配了才进入pot
  而我这里, 可以假定只要一下注, 反正最终都会进入pot的

  位置的简化
  实际当中, 肯定会考虑位置优势, OP玩家下注之后不一定能马上进入下一轮
  而我这里还没到后续复杂的AI编程部分, 暂时先不考虑位置因素

  大盲的问题
  目前因为并没有真正进行任何有效的计算, 似乎应该不必要把大盲整理成1
  然后所有的下注都翻译成几个大盲, 这些留到之后再说即可
  """

  defstruct [
    :my_chips,
    :oppo_chips,
    round: :preflop,
    pot: 0,
    amount_to_call: 0,
    hole_cards: [],
    community_cards: []
  ]

  def new(my_chips, oppo_chips) do
    %Table{
      my_chips: my_chips,
      oppo_chips: oppo_chips
    }
  end

  def make_bet(%Table{pot: pot, my_chips: my_chips} = table, :me, amount) do
    %Table{table | pot: pot + amount, my_chips: my_chips - amount}
  end

  def make_bet(%Table{pot: pot, oppo_chips: oppo_chips} = table, :oppo, amount) do
    %Table{table | pot: pot + amount, oppo_chips: oppo_chips - amount}
  end

  def update_amount_to_call(%Table{} = table, amount_to_call) do
    %Table{table | amount_to_call: amount_to_call}
  end

  def deal_hole_cards(%Table{} = table, hole_cards) do
    %Table{table | hole_cards: hole_cards}
  end

  def deal_community_cards(
        %Table{round: current_round, community_cards: old_cards} = table,
        new_cards
      ) do
    %Table{table | round: next_round(current_round), community_cards: old_cards ++ new_cards}
  end

  defp next_round(:preflop), do: :flop
  defp next_round(:flop), do: :turn
  defp next_round(:turn), do: :river
end
