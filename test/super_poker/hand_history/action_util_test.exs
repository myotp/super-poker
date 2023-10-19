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
            {:player, "Anna", {:raise, 10}},
            {:player, "Lucas", {:call, 10}}
          ]
        }

      assert ActionUtil.prepare_player_actions_attrs(hh.actions, "Anna") ==
               %{
                 username: "Anna",
                 preflop: [%{action: :call, amount: 0.25}, %{action: :call, amount: 5}],
                 flop: [%{action: :raise, amount: 10}, %{action: :raise, amount: 40}],
                 turn: [%{action: :check, amount: 0}],
                 river: [%{action: :raise, amount: 10}]
               }
    end
  end

  describe "recreate_table_and_player_actions/1" do
    test "满操作重新构建" do
      sp_game =
        %{
          button_pos: 1,
          players: [
            %{pos: 1, username: "Anna", chips: 600},
            %{pos: 2, username: "Lucas", chips: 500}
          ],
          community_cards: "AH KH QH JH TH",
          player_actions: [
            %{
              game_id: 100,
              username: "Lucas",
              preflop: [%{action: :check, amount: 0}],
              flop: [%{action: :check, amount: 0}],
              turn: [%{action: :check, amount: 0}],
              river: [
                %{action: :check, amount: 0},
                %{action: :raise, amount: 30},
                %{action: :call, amount: 30}
              ]
            },
            %{
              game_id: 100,
              username: "Anna",
              preflop: [%{action: :call, amount: 5}],
              flop: [%{action: :check, amount: 0}],
              turn: [%{action: :check, amount: 0}],
              river: [
                %{action: :raise, amount: 10},
                %{action: :raise, amount: 50}
              ]
            }
          ]
        }

      assert ActionUtil.recreate_table_and_player_actions(sp_game) == [
               {:player, "Anna", {:call, 5}},
               {:player, "Lucas", :check},
               {:deal, :flop, "AH KH QH"},
               {:player, "Lucas", :check},
               {:player, "Anna", :check},
               {:deal, :turn, "AH KH QH JH"},
               {:player, "Lucas", :check},
               {:player, "Anna", :check},
               {:deal, :river, "AH KH QH JH TH"},
               {:player, "Lucas", :check},
               {:player, "Anna", {:raise, 10}},
               {:player, "Lucas", {:raise, 30}},
               {:player, "Anna", {:raise, 50}},
               {:player, "Lucas", {:call, 30}}
             ]
    end
  end

  describe "merge_two_lists_one_by_one/2" do
    test "功能函数独立测试先" do
      assert ActionUtil.merge_two_lists_one_by_one([:a1, :a2], [:b1, :b2]) == [:a1, :b1, :a2, :b2]
    end

    test "双方操作数量不等的时候" do
      assert ActionUtil.merge_two_lists_one_by_one([:a1, :a2, :a3], [:b1, :b2]) == [
               :a1,
               :b1,
               :a2,
               :b2,
               :a3
             ]
    end
  end
end
