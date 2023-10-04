defmodule SuperPoker.GameServer.HeadsupTableStateTest do
  alias SuperPoker.GameServer.HeadsupTableState, as: State
  use ExUnit.Case

  describe "new/1" do
  end

  describe "join_table/2" do
    test "第一位玩家正确加入" do
      state = State.new(%{max_players: 2, buyin: 500})
      assert {:ok, state} = State.join_table(state, "anna")
      assert state.players[0].pos == 0
      assert state.players[0].username == "anna"
      assert state.players[0].chips == 500
      assert state.players[0].status == :JOINED
    end

    test "第二位玩家加入" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      assert state.players[1].username == "bob"
    end

    test "第三位玩家无法加入两人桌" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      assert {:error, :table_full} = State.join_table(state, "cry")
      assert state.players[0].username == "anna"
      assert state.players[1].username == "bob"
    end

    test "玩家离开桌子" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.leave_table(state, "anna")
      assert state.players[0] == nil
    end

    test "玩家离开的情况下可以正常处理" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.leave_table(state, "anna")
      assert {:ok, state} = State.join_table(state, "cry")
      assert state.players[0].username == "cry"
      assert state.players[1].username == "bob"
    end

    test "玩家重复加入桌子的情况" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:error, :already_in_table} = State.join_table(state, "anna")
    end

    test "玩家离开不在的桌子" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:error, :not_in_table} = State.leave_table(state, "anna")
    end
  end

  describe "player_start_game/2" do
    test "玩家start" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      assert state.players[0].status == :JOINED
      {:ok, state} = State.player_start_game(state, "anna")
      assert state.players[0].status == :READY
    end
  end

  describe "can_table_start_game?/1" do
    test "两玩家都已经准备则游戏可以开始" do
      state = State.new(%{max_players: 2, buyin: 500})
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
      state = State.new(%{max_players: 2, buyin: 500})
      assert state.table_status == :WAITING
    end

    test "两玩家都准备好之后, 桌子启动新游戏进入RUNNING状态" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.player_start_game(state, "anna")
      {:ok, state} = State.player_start_game(state, "bob")
      {:ok, state} = State.table_start_game!(state)
      assert state.table_status == :RUNNING
      assert [_ | _] = state.deck
      assert Enum.count(state.deck) == 52
      assert state.community_cards == []
      assert state.players_cards == %{}
      assert state.players[0].current_street_bet == 0
      assert state.players[1].current_street_bet == 0
    end
  end

  describe "deal_hole_cards!/1" do
    test "测试给玩家发牌" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.player_start_game(state, "anna")
      {:ok, state} = State.player_start_game(state, "bob")
      {:ok, state} = State.table_start_game!(state)
      [c1, c2, c3, c4 | rest] = state.deck
      state = State.deal_hole_cards!(state)
      assert state.players_cards[0] == [c1, c2]
      assert state.players_cards[1] == [c3, c4]
      assert state.deck == rest
    end
  end

  describe "hole_cards_info!/1" do
    test "生成给每个玩家自己的hole_card信息" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.player_start_game(state, "anna")
      {:ok, state} = State.player_start_game(state, "bob")
      {:ok, state} = State.table_start_game!(state)
      state = State.deal_hole_cards!(state)

      assert State.hole_cards_info!(state) == [
               {"anna", state.players_cards[0]},
               {"bob", state.players_cards[1]}
             ]
    end
  end

  describe "deal_community_cards/2" do
    test "测试发牌" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.player_start_game(state, "anna")
      {:ok, state} = State.player_start_game(state, "bob")
      {:ok, state} = State.table_start_game!(state)
      [c1, c2, c3, c4, c5 | rest] = state.deck
      assert state.community_cards == []
      state = State.deal_community_cards!(state, :flop)
      assert state.community_cards == [c1, c2, c3]
      state = State.deal_community_cards!(state, :turn)
      assert state.community_cards == [c1, c2, c3, c4]
      state = State.deal_community_cards!(state, :river)
      assert state.community_cards == [c1, c2, c3, c4, c5]
      assert state.deck == rest
    end
  end

  describe "all_players/1" do
    test "一个玩家的时候" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      assert ["anna"] == State.all_players(state)
    end

    test "两个玩家" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      assert ["anna", "bob"] == State.all_players(state)
    end

    test "玩家离开的情况" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      {:ok, state} = State.leave_table(state, "anna")
      assert ["bob"] == State.all_players(state)
    end
  end

  describe "players_info/1" do
    test "没有玩家的时候" do
      state = State.new(%{max_players: 2, buyin: 500})
      assert [] == State.players_info(state)
    end

    test "一个玩家加入" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")

      assert [%{"anna" => %{username: "anna", chips: 500, status: :JOINED}}] ==
               State.players_info(state)
    end

    test "两个玩家加入" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")

      assert [
               %{"anna" => %{username: "anna", chips: 500, status: :JOINED}},
               %{"bob" => %{username: "bob", chips: 500, status: :JOINED}}
             ] ==
               State.players_info(state)
    end
  end

  describe "generate_players_data_for_rules_engine/1" do
    test "两玩家对战情况" do
      state = State.new(%{max_players: 2, buyin: 500})
      {:ok, state} = State.join_table(state, "anna")
      {:ok, state} = State.join_table(state, "bob")
      assert %{0 => 500, 1 => 500} == State.generate_players_data_for_rules_engine(state)
    end
  end
end
