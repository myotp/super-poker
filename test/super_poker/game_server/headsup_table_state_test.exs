defmodule SuperPoker.GameServer.HeadsupTableStateTest do
  use ExUnit.Case

  alias SuperPoker.GameServer.HeadsupTableState, as: State
  alias SuperPoker.Core.Hand
  alias SuperPoker.HandHistory.HandHistory

  describe "new/1" do
  end

  defp default_table_config() do
    %{max_players: 2, buyin: 500, sb: 5, bb: 10}
  end

  describe "join_table/2" do
    test "第一位玩家正确加入" do
      state = State.new(default_table_config())
      assert {:ok, state} = State.join_table(state, "anna")
      assert state.players[0].pos == 0
      assert state.players[0].username == "anna"
      assert state.players[0].status == :JOINED
      assert state.chips["anna"] == 500
    end

    test "第二位玩家加入" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      assert state.players[1].username == "bob"
    end

    test "第三位玩家无法加入两人桌" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      assert {:error, :table_full} = State.join_table(state, "cry")
      assert state.players[0].username == "anna"
      assert state.players[1].username == "bob"
    end

    test "玩家离开桌子" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, 500, state} = State.leave_table(state, "anna")
      assert state.players[0] == nil
    end

    test "玩家离开的情况下可以正常处理" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, _chips_left, state} = State.leave_table(state, "anna")
      assert {:ok, state} = State.join_table(state, "cry")
      assert state.players[0].username == "cry"
      assert state.players[1].username == "bob"
    end

    test "玩家重复加入桌子的情况" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:error, :already_in_table} = State.join_table(state, "anna")
    end

    test "玩家离开不在的桌子" do
      state = State.new(default_table_config())
      {:error, :not_in_table} = State.leave_table(state, "anna")
    end
  end

  describe "player_start_game/2" do
    test "玩家start" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      assert state.players[0].status == :JOINED
      {:ok, state} = State.player_start_game(state, "anna")
      assert state.players[0].status == :READY
    end
  end

  describe "can_table_start_game?/1" do
    test "两玩家都已经准备则游戏可以开始" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.player_start_game(state, "anna")
      assert State.can_table_start_game?(state) == false
      {:ok, state} = State.player_start_game(state, "bob")
      assert State.can_table_start_game?(state) == true
    end
  end

  describe "table_start_game!/1" do
    test "没有玩家就位, 桌子默认为WAITING状态" do
      state = State.new(default_table_config())
      assert state.table_status == :WAITING
    end

    test "两玩家都准备好之后, 桌子启动新游戏进入RUNNING状态" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.player_start_game(state, "anna")
      {:ok, state} = State.player_start_game(state, "bob")
      state = State.table_start_game!(state)
      assert state.table_status == :RUNNING
      assert [_ | _] = state.deck
      assert Enum.count(state.deck) == 52
      assert state.community_cards == []
      assert state.players_cards == %{}
      assert state.players[0].current_street_bet == 0
      assert state.players[1].current_street_bet == 0
    end

    test "hand_history: 桌子启动新游戏初始化HandHistory" do
      ts_before_start = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      state = State.new(default_table_config())
      assert state.hand_history == nil
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.player_start_game(state, "anna")
      {:ok, state} = State.player_start_game(state, "bob")
      state = State.table_start_game!(state)

      assert %HandHistory{
               button_pos: 0,
               sb_amount: 5,
               bb_amount: 10,
               community_cards: "",
               start_time: start_time,
               players: players,
               blinds: blinds
             } =
               state.hand_history

      assert NaiveDateTime.diff(start_time, ts_before_start) < 3

      assert [%{pos: 0, username: "anna", chips: 500}, %{pos: 1, username: "bob", chips: 500}] =
               players |> Enum.sort()

      assert [%{username: "anna", amount: 5}, %{username: "bob", amount: 10}] =
               blinds |> Enum.sort()
    end
  end

  describe "table_finish_game!/1" do
    test "接到结束牌局通知后桌子结束游戏并回到WAITING状态" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.player_start_game(state, "anna")
      {:ok, state} = State.player_start_game(state, "bob")
      state = State.table_start_game!(state)
      state = State.table_finish_game!(state, %{"anna" => 600, "bob" => 400})
      assert state.table_status == :WAITING
      assert state.chips["anna"] == 600
      assert state.chips["bob"] == 400
      assert state.players[0].status == :JOINED
      assert state.players[1].status == :JOINED
    end
  end

  describe "deal_hole_cards!/1" do
    test "测试给玩家发牌" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.player_start_game(state, "anna")
      {:ok, state} = State.player_start_game(state, "bob")
      state = State.table_start_game!(state)
      [c1, c2, c3, c4 | rest] = state.deck
      state = State.deal_hole_cards!(state)
      assert state.players_cards[0] == [c1, c2]
      assert state.players_cards[1] == [c3, c4]
      assert state.deck == rest

      assert %{"anna" => hand1, "bob" => hand2} = state.hand_history.hole_cards
      assert [_, _] = String.split(hand1, " ")
      assert [_, _] = String.split(hand2, " ")
    end
  end

  describe "hole_cards_info!/1" do
    test "生成给每个玩家自己的hole_card信息" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.player_start_game(state, "anna")
      {:ok, state} = State.player_start_game(state, "bob")
      state = State.table_start_game!(state)
      state = State.deal_hole_cards!(state)

      assert State.hole_cards_info!(state) == [
               {"anna", state.players_cards[0]},
               {"bob", state.players_cards[1]}
             ]
    end
  end

  describe "deal_community_cards/2" do
    test "测试发牌" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.player_start_game(state, "anna")
      {:ok, state} = State.player_start_game(state, "bob")
      state = State.table_start_game!(state)
      [c1, c2, c3, c4, c5 | rest] = state.deck
      assert state.community_cards == []
      assert {[^c1, ^c2, ^c3], state} = State.deal_community_cards!(state, :flop)
      assert state.community_cards == [c1, c2, c3]
      assert {[^c4], state} = State.deal_community_cards!(state, :turn)
      assert state.community_cards == [c1, c2, c3, c4]
      assert {[^c5], state} = State.deal_community_cards!(state, :river)
      assert state.community_cards == [c1, c2, c3, c4, c5]
      assert state.deck == rest
    end
  end

  describe "all_players/1" do
    test "一个玩家的时候" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      assert ["anna"] == State.all_players(state)
    end

    test "两个玩家" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      assert ["anna", "bob"] == State.all_players(state)
    end

    test "玩家离开的情况" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, _, state} = State.leave_table(state, "anna")
      assert ["bob"] == State.all_players(state)
    end
  end

  describe "players_info/1" do
    test "没有玩家的时候" do
      state = State.new(default_table_config())
      assert [] == State.players_info(state)
    end

    test "一个玩家加入" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")

      assert [%{username: "anna", chips: 500, status: :JOINED}] ==
               State.players_info(state)
    end

    test "两个玩家加入" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")

      assert [
               %{username: "anna", chips: 500, status: :JOINED},
               %{username: "bob", chips: 500, status: :JOINED}
             ]
             |> Enum.sort() ==
               State.players_info(state) |> Enum.sort()
    end
  end

  describe "generate_players_data_for_rules_engine/1" do
    test "两玩家对战情况" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")

      assert {%{0 => 500, 1 => 500}, %{0 => "anna", 1 => "bob"}} ==
               State.generate_players_data_for_rules_engine(state)
    end
  end

  describe "decide_winner/1" do
    test "两玩家最后摊牌比大小玩家1获胜" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")

      state =
        state
        |> Map.put(:community_cards, Hand.from_string("QH JH TH 9H 8H"))
        |> Map.put(:players_cards, %{
          0 => Hand.from_string("AH KH"),
          1 => Hand.from_string("7H 6H")
        })

      assert {"anna", :royal_flush, _, _} = State.decide_winner(state)
    end

    test "两玩家最后摊牌比大小玩家2获胜" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")

      state =
        state
        |> Map.put(:community_cards, Hand.from_string("QH JH TH 9H 8H"))
        |> Map.put(:players_cards, %{
          0 => Hand.from_string("7H AS"),
          1 => Hand.from_string("KH 7S")
        })

      bob_best = Hand.from_string("KH QH JH TH 9H")
      assert {"bob", :straight_flush, ^bob_best, _} = State.decide_winner(state)
    end

    test "两玩家最后摊牌比大小平局的情况" do
      state = State.new(default_table_config())
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")

      state =
        state
        |> Map.put(:community_cards, Hand.from_string("AH KH QH JH TH"))
        |> Map.put(:players_cards, %{
          0 => Hand.from_string("2H 2D"),
          1 => Hand.from_string("2S 2C")
        })

      assert {nil, :royal_flush, _, _} = State.decide_winner(state)
    end
  end
end
