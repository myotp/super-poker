defmodule SuperPoker.HandHistory.PokerstarsExporterTest do
  use ExUnit.Case

  alias SuperPoker.HandHistory.PokerstarsExporter
  alias SuperPoker.HandHistory.HandHistory

  describe "to_string/1" do
    test "完整测试" do
      hand_history =
        %HandHistory{
          game_id: 246_357_379_051,
          start_time: NaiveDateTime.from_iso8601!("2023-10-17 15:59:40"),
          players: [
            %{pos: 3, username: "Lucas", chips: 15},
            %{pos: 5, username: "Anna", chips: 20}
          ],
          button_pos: 5,
          sb_amount: 0.25,
          bb_amount: 0.5,
          blinds: [%{username: "Lucas", amount: 0.5}, %{username: "Anna", amount: 0.25}],
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

      assert PokerstarsExporter.to_string(hand_history, "Lucas") ==
               """
               PokerStars Hand #246357379051:  Hold'em No Limit ($0.25/$0.50 USD) - 2023/10/17 15:59:40 ET
               Table 'Vala' 6-max Seat #5 is the button
               Seat 3: Lucas ($15 in chips)
               Seat 5: Anna ($20 in chips)
               Anna: posts small blind $0.25
               Lucas: posts big blind $0.50
               *** HOLE CARDS ***
               Dealt to Lucas [Ah Qc]
               Anna: calls $0.25
               Lucas: checks
               *** FLOP *** [Qh 7h 5d]
               Lucas: checks
               Anna: checks
               *** TURN *** [Qh 7h 5d] [8c]
               Lucas: checks
               Anna: checks
               *** RIVER *** [Qh 7h 5d 8c] [9s]
               Lucas: checks
               Anna: checks
               *** SUMMARY ***
               Board [Qh 7h 5d 8c 9s]
               """
               |> String.trim_trailing("\n")
    end
  end

  describe "table_metadata/1" do
    test "普通二人对战桌子" do
      hand_history =
        %HandHistory{
          game_id: 246_357_885_966,
          sb_amount: 0.25,
          bb_amount: 0.5,
          start_time: NaiveDateTime.from_iso8601!("2023-10-17 15:59:40"),
          button_pos: 5,
          players: %{3 => %{username: "Lucas", chips: 15}, 5 => %{username: "Anna", chips: 20}}
        }

      assert PokerstarsExporter.table_metadata(hand_history) ==
               """
               PokerStars Hand #246357885966:  Hold'em No Limit ($0.25/$0.50 USD) - 2023/10/17 15:59:40 ET
               Table 'Vala' 6-max Seat #5 is the button
               """
               |> String.trim_trailing("\n")
    end
  end

  describe "players_info/1" do
    test "生成玩家信息" do
      hand_history =
        %HandHistory{
          players: [
            %{pos: 3, username: "Lucas", chips: 15},
            %{pos: 5, username: "Anna", chips: 20}
          ]
        }

      assert PokerstarsExporter.players_info(hand_history) ==
               """
               Seat 3: Lucas ($15 in chips)
               Seat 5: Anna ($20 in chips)
               """
               |> String.trim_trailing("\n")
    end
  end

  describe "blinds_info/1" do
    test "标准二人盲注" do
      hand_history =
        %HandHistory{
          blinds: [%{username: "Anna", amount: 0.25}, %{username: "Lucas", amount: 0.5}]
        }

      assert PokerstarsExporter.blinds_info(hand_history) ==
               """
               Anna: posts small blind $0.25
               Lucas: posts big blind $0.50
               """
               |> String.trim_trailing("\n")
    end
  end

  describe "hole_cards/2" do
    test "根据GTO Wizard要求hero必须" do
      hand_history =
        %HandHistory{
          hole_cards: %{"Lucas" => "AH QC", "Anna" => "3D 2D"}
        }

      assert PokerstarsExporter.hole_cards_info(hand_history, "Lucas") ==
               """
               *** HOLE CARDS ***
               Dealt to Lucas [Ah Qc]
               """
               |> String.trim_trailing("\n")
    end
  end

  describe "action_to_string/1" do
    test "deal flop" do
      assert PokerstarsExporter.action_to_string({:deal, :flop, "AH KH 9H"}) ==
               "*** FLOP *** [Ah Kh 9h]"
    end

    test "deal turn" do
      assert PokerstarsExporter.action_to_string({:deal, :turn, "AH KH 9H 8H"}) ==
               "*** TURN *** [Ah Kh 9h] [8h]"
    end

    test "deal river" do
      assert PokerstarsExporter.action_to_string({:deal, :river, "AH KH 9H 8H 7H"}) ==
               "*** RIVER *** [Ah Kh 9h 8h] [7h]"
    end

    test "check" do
      assert PokerstarsExporter.action_to_string({:player, "Anna", :check}) == "Anna: checks"
    end

    test "call" do
      assert PokerstarsExporter.action_to_string({:player, "Anna", {:call, 0.05}}) ==
               "Anna: calls $0.05"
    end
  end

  describe "summary/1" do
    test "简单只显示公共牌即可" do
      hand_history = %HandHistory{community_cards: "QH 7H 5D 8C 9S"}

      assert PokerstarsExporter.summary(hand_history) ==
               """
               *** SUMMARY ***
               Board [Qh 7h 5d 8c 9s]
               """
               |> String.trim_trailing("\n")
    end
  end
end
