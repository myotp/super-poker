defmodule SuperPoker.HandHistory.ActionUtilTest do
  use ExUnit.Case

  alias SuperPoker.HistoryPersist.ActionUtil
  alias SuperPoker.HandHistory.HandHistory

  describe "prepare_player_actions_attrs/2" do
    test "基本操作" do
      # 数据来源PokerstarsExporterTest
      hh =
        %HandHistory{
          game_id: 5678,
          actions: [
            {:player, "Anna", {:call, 0.25}},
            {:player, "Lucas", {:raise, 5}},
            {:player, "Anna", {:call, 5}},
            {:deal, :flop, "QH 7H 5D"},
            {:player, "Lucas", :check},
            {:player, "Anna", {:raise, 10}},
            {:player, "Lucas", {:raise, 20}},
            {:player, "Anna", {:raise, 40}},
            {:player, "Lucas", {:call, 30}},
            {:deal, :turn, "QH 7H 5D 8C"},
            {:player, "Lucas", :check},
            {:player, "Anna", :check},
            {:deal, :river, "QH 7H 5D 8C 9S"},
            {:player, "Lucas", :check},
            {:player, "Anna", :check}
          ]
        }

      assert ActionUtil.prepare_player_actions_attrs(hh.actions, "Anna") ==
               %{
                 username: "Anna",
                 preflop: [%{action: "call", amount: 0.25}, %{action: "call", amount: 5}],
                 flop: [%{action: "raise", amount: 10}, %{action: "raise", amount: 40}],
                 turn: [%{action: "check", amount: 0}],
                 river: [%{action: "check", amount: 0}]
               }
    end
  end
end
