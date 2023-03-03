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

    @tag :skip
    # TODO
    test "玩家只有在牌局没开始情况下离开" do
      assert 1 == 2
    end
  end
end
