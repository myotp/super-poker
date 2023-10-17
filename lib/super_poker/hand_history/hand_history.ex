defmodule SuperPoker.HandHistory.HandHistory do
  defstruct [
    # 牌桌游戏对局的基本信息, 一些固定硬编码的在最后
    :game_id,
    :start_time,

    # 大小盲及盲注下注信息, 多人底池谁下多少盲由rules给出指引
    :sb_amount,
    :bb_amount,
    :blinds,
    :button_pos,

    # 玩家信息, 座位号, 用户名, 筹码数量
    :players,

    # 动态牌信息
    :community_cards,
    :hole_cards,

    # 一系列发牌玩家操作事件列表
    :actions,

    # hard coded attrs
    format: "PokerStars",
    table_name: "Vala",
    poker_type: "Hold'em No Limit",
    table_type: "6-max"
  ]

  def example_actions() do
    [
      {:deal, :flop, "8d 5d Ac"}
    ]
  end
end
