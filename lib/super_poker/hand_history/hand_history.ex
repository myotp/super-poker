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

  def example() do
    %__MODULE__{
      game_id: 246_358_000_000 + Enum.random(352_189..979_633),
      start_time: NaiveDateTime.utc_now(),
      players: %{3 => %{username: "Lucas", chips: 15}, 5 => %{username: "Anna", chips: 20}},
      button_pos: 5,
      sb_amount: 0.25,
      bb_amount: 0.5,
      blinds: %{"Lucas" => 0.5, "Anna" => 0.25},
      hole_cards: %{"Lucas" => "AH QC", "Anna" => "3D 2D"},
      community_cards: "QH 7H 5D 8C 9S",
      actions: [
        {:player, "Anna", {:call, 0.25}},
        {:player, "Lucas", :check},
        {:deal, :flop, "QH 7H 5D"},
        {:player, "Lucas", :check},
        {:player, "Anna", :check},
        {:deal, :turn, "QH 7H 5D 8C"},
        {:player, "Lucas", :check},
        {:player, "Anna", :check},
        {:deal, :river, "QH 7H 5D 8C 9S"},
        {:player, "Lucas", :check},
        {:player, "Anna", :check}
      ]
    }
  end
end
