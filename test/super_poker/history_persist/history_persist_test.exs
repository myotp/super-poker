defmodule SuperPoker.HistoryPersist.HistoryPersistTest do
  use SuperPoker.DataCase

  alias SuperPoker.HistoryPersist.SpPlayerAction
  alias SuperPoker.HistoryPersist
  alias SuperPoker.HandHistory.HandHistory
  alias SuperPoker.HistoryPersist.SpGame
  alias SuperPoker.HistoryPersist.SpGamePlayer
  alias SuperPoker.HistoryPersist.SpPlayerAction
  alias SuperPoker.HistoryPersist.SpPlayerAction.PlayerAction

  describe "save_hand_history/1" do
    test "独立验证写入数据库过程的顺利" do
      start_time = NaiveDateTime.from_iso8601!("2023-10-17 15:59:40")

      # 仿照PokerstarsExporterTest构造测试数据
      hand_history =
        %HandHistory{
          start_time: start_time,
          players: [
            %{pos: 3, username: "Lucas", chips: 500},
            %{pos: 5, username: "Anna", chips: 600}
          ],
          button_pos: 5,
          sb_amount: 5,
          bb_amount: 10,
          blinds: [%{username: "Anna", amount: 5}, %{username: "Lucas", amount: 10}],
          hole_cards: %{"Anna" => "3D 2D", "Lucas" => "AH QC"},
          community_cards: "QH 7H 5D 8C 9S",
          actions: [
            {:player, "Anna", {:call, 5}},
            {:player, "Lucas", :check},
            {:deal, :flop, "QH 7H 5D"},
            {:player, "Lucas", :check},
            {:player, "Anna", :check},
            {:deal, :turn, "QH 7H 5D 8C"},
            {:player, "Lucas", :check},
            {:player, "Anna", :check},
            {:deal, :river, "QH 7H 5D 8C 9S"},
            {:player, "Lucas", {:raise, 10}},
            {:player, "Anna", {:raise, 20}},
            {:player, "Lucas", {:raise, 50}},
            {:player, "Anna", {:call, 40}}
          ]
        }

      # 通过API模块HistoryPersist写入数据库并返回自动生成game_id
      assert {:ok, game_id} = HistoryPersist.save_hand_history(hand_history)

      # =1= 验证game本身写入正确
      %SpGame{
        id: ^game_id,
        start_time: ^start_time,
        button_pos: 5,
        sb_amount: 5.0,
        bb_amount: 10.0,
        community_cards: "QH 7H 5D 8C 9S",
        # FIXME: missing blinds
        players: players,
        player_actions: player_actions
      } =
        SpGame.read_game_history_from_db(game_id)

      # =2= 验证has_many的players写入正确
      player_anna = Enum.find(players, fn p -> p.username == "Anna" end)
      player_lucas = Enum.find(players, fn p -> p.username == "Lucas" end)

      assert %SpGamePlayer{
               username: "Anna",
               pos: 5,
               chips: 600.0
             } = player_anna

      assert %SpGamePlayer{
               username: "Lucas",
               pos: 3,
               chips: 500.0
             } = player_lucas

      # =3= 验证独立写入的player_actions写入正确
      anna_actions = Enum.find(player_actions, fn a -> a.username == "Anna" end)
      lucas_actions = Enum.find(player_actions, fn a -> a.username == "Lucas" end)

      assert %SpPlayerAction{
               game_id: ^game_id,
               username: "Lucas",
               preflop: [%PlayerAction{action: :check, amount: 0.0}],
               flop: [%PlayerAction{action: :check, amount: 0.0}],
               turn: [%PlayerAction{action: :check, amount: 0.0}],
               river: [
                 %PlayerAction{action: :raise, amount: 10.0},
                 %PlayerAction{action: :raise, amount: 50.0}
               ]
             } = lucas_actions

      assert %SpPlayerAction{
               game_id: ^game_id,
               username: "Anna",
               preflop: [%PlayerAction{action: :call, amount: 5.0}],
               flop: [%PlayerAction{action: :check, amount: 0.0}],
               turn: [%PlayerAction{action: :check, amount: 0.0}],
               river: [
                 %PlayerAction{action: :raise, amount: 20.0},
                 %PlayerAction{action: :call, amount: 40.0}
               ]
             } = anna_actions
    end
  end

  describe "load_hand_history/1" do
    test "从数据库中读取并转换成内存表示格式" do
      start_time = NaiveDateTime.from_iso8601!("2023-10-17 15:59:40")

      # 仿照PokerstarsExporterTest构造测试数据
      hh =
        %HandHistory{
          start_time: start_time,
          players: [
            %{pos: 3, username: "Lucas", chips: 500},
            %{pos: 5, username: "Anna", chips: 600}
          ],
          button_pos: 5,
          sb_amount: 5,
          bb_amount: 10,
          blinds: [%{username: "Anna", amount: 5}, %{username: "Lucas", amount: 10}],
          hole_cards: %{"Anna" => "3D 2D", "Lucas" => "AH QC"},
          community_cards: "QH 7H 5D 8C 9S",
          actions: [
            {:player, "Anna", {:call, 5}},
            {:player, "Lucas", :check},
            {:deal, :flop, "QH 7H 5D"},
            {:player, "Lucas", :check},
            {:player, "Anna", :check},
            {:deal, :turn, "QH 7H 5D 8C"},
            {:player, "Lucas", :check},
            {:player, "Anna", :check},
            {:deal, :river, "QH 7H 5D 8C 9S"},
            {:player, "Lucas", {:raise, 10}},
            {:player, "Anna", {:raise, 20}},
            {:player, "Lucas", {:raise, 50}},
            {:player, "Anna", {:call, 40}}
          ]
        }

      # 通过API模块HistoryPersist写入数据库并返回自动生成game_id
      assert {:ok, game_id} = HistoryPersist.save_hand_history(hh)

      assert HistoryPersist.load_hand_history(game_id) == %HandHistory{hh | game_id: game_id}
    end
  end
end
