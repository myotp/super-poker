# TODO: 明确了通过username的话，就可以定义dummy版本，方便测试了，研究后续到底该咋测试
# TODO: 我现在直接用默认的1001的话，会有所冲突，每个建新的话，如何后继前边的状态呢
# TODO: 尽管有Emacs可以方便插入代码到shell，还是尽量不要那么用，而是通过测试，把代码攒出来
defmodule SuperPoker.Multiplayer.HeadsupTableServerTest do
  use ExUnit.Case, async: false
  alias SuperPoker.Multiplayer.HeadsupTableServer
  alias SuperPoker.Multiplayer.TableSup

  @table_config %{
    id: 1001,
    max_players: 2,
    sb: 5,
    bb: 10,
    buyin: 500,
    table: SuperPoker.Multiplayer.HeadsupTableServer,
    rules: SuperPoker.RulesEngine.SimpleRules1v1
  }

  describe "单挑牌桌测试" do
    test "最多只能两个玩家加入" do
      TableSup.start_table(%{@table_config | id: 9001})
      s = HeadsupTableServer.get_state(9001)
      assert s.p0 == nil
      assert s.p1 == nil
      assert s.table_status == :WAITING

      assert HeadsupTableServer.join_table(9001, "anna") == :ok
      s = HeadsupTableServer.get_state(9001)
      assert s.p0.username == "anna"
      assert s.p1 == nil

      assert HeadsupTableServer.join_table(9001, "bob") == :ok
      s = HeadsupTableServer.get_state(9001)
      assert s.p0.username == "anna"
      assert s.p1.username == "bob"

      assert HeadsupTableServer.join_table(9001, "catlina") == {:error, :table_full}
    end

    test "玩家开始牌局" do
      TableSup.start_table(%{@table_config | id: 9002})
      HeadsupTableServer.join_table(9002, "anna")
      HeadsupTableServer.join_table(9002, "bob")

      assert HeadsupTableServer.start_game(9002, "anna") == :ok
      s = HeadsupTableServer.get_state(9002)
      assert s.p0.status == :READY
      assert s.p1.status == :JOINED
      assert s.table_status == :WAITING

      assert HeadsupTableServer.start_game(9002, "bob") == :ok
      s = HeadsupTableServer.get_state(9002)
      assert s.p0.status == :READY
      assert s.p1.status == :READY
      assert s.table_status == :RUNNING
      assert s.table != nil
    end

    test "简单一方fold迅速完整完成一局对战并验证筹码更新" do
      TableSup.start_table(%{@table_config | id: 9003})
      HeadsupTableServer.join_table(9003, "anna")
      HeadsupTableServer.join_table(9003, "bob")
      HeadsupTableServer.start_game(9003, "anna")
      HeadsupTableServer.start_game(9003, "bob")
      s = HeadsupTableServer.get_state(9003)
      assert s.table.next_action == {:player, {0, [:fold, {:call, 5}, :raise]}}
      HeadsupTableServer.player_action_done(9003, "anna", :fold)
      s = HeadsupTableServer.get_state(9003)
      assert s.table.next_action == {:winner, 1, %{0 => 495, 1 => 505}}
      # 确认最终玩家筹码正确设置
      assert s.p0.chips == 495
      assert s.p1.chips == 505
      # 桌子回到等待状态
      assert s.table_status == :WAITING
    end

    test "普通call以及check验证后续发牌轮" do
      TableSup.start_table(%{@table_config | id: 9004})
      HeadsupTableServer.join_table(9004, "anna")
      HeadsupTableServer.join_table(9004, "bob")
      HeadsupTableServer.start_game(9004, "anna")
      HeadsupTableServer.start_game(9004, "bob")

      # preflop轮下注
      HeadsupTableServer.player_action_done(9004, "anna", :call)
      HeadsupTableServer.player_action_done(9004, "bob", :check)

      # 牌桌完成自动发牌flop
      s = HeadsupTableServer.get_state(9004)
      assert s.table.current_street == :flop
      assert s.table.next_action == {:player, {1, [:fold, :check, :raise]}}
      HeadsupTableServer.player_action_done(9004, "bob", :check)
      HeadsupTableServer.player_action_done(9004, "anna", :check)

      # 牌桌完成发牌turn
      s = HeadsupTableServer.get_state(9004)
      assert s.table.current_street == :turn
      assert s.table.next_action == {:player, {1, [:fold, :check, :raise]}}
      HeadsupTableServer.player_action_done(9004, "bob", :check)
      HeadsupTableServer.player_action_done(9004, "anna", :check)

      # 牌桌完成发牌turn
      s = HeadsupTableServer.get_state(9004)
      assert s.table.current_street == :river
      assert s.table.next_action == {:player, {1, [:fold, :check, :raise]}}
      HeadsupTableServer.player_action_done(9004, "bob", :check)
      HeadsupTableServer.player_action_done(9004, "anna", :check)

      # 最终牌局结束
      s = HeadsupTableServer.get_state(9004)
      assert s.table_status == :WAITING
      # 确定玩家回到等待状态
      assert s.p0.status == :JOINED
    end

    @tag :wip
    test "发牌流程测试" do
      TableSup.start_table(%{@table_config | id: 9005})
      HeadsupTableServer.join_table(9005, "anna")
      HeadsupTableServer.join_table(9005, "bob")
      HeadsupTableServer.start_game(9005, "anna")
      HeadsupTableServer.start_game(9005, "bob")
      s = HeadsupTableServer.get_state(9005)
      assert s.deck != []
      assert s.community_cards == []
      assert [_, _] = cards0 = s.player_cards[0]
      assert [_, _] = cards1 = s.player_cards[1]
      HeadsupTableServer.player_action_done(9005, "anna", :call)
      HeadsupTableServer.player_action_done(9005, "bob", :check)
      # 发出flop
      s = HeadsupTableServer.get_state(9005)
      assert Enum.count(s.community_cards) == 3
      # 玩家手牌不变
      assert s.player_cards[0] == cards0
      assert s.player_cards[1] == cards1
      HeadsupTableServer.player_action_done(9005, "bob", :check)
      HeadsupTableServer.player_action_done(9005, "anna", :check)

      # 发出turn
      s = HeadsupTableServer.get_state(9005)
      assert Enum.count(s.community_cards) == 4
      HeadsupTableServer.player_action_done(9005, "bob", :check)
      HeadsupTableServer.player_action_done(9005, "anna", :check)

      # 发出river
      s = HeadsupTableServer.get_state(9005)
      assert Enum.count(s.community_cards) == 5
      HeadsupTableServer.player_action_done(9005, "bob", :check)
      HeadsupTableServer.player_action_done(9005, "anna", :check)
      s = HeadsupTableServer.get_state(9005)
      assert s.table_status == :WAITING
    end

    @tag :skip
    # TODO
    test "玩家只有在牌局没开始情况下离开" do
      assert 1 == 2
    end
  end
end
