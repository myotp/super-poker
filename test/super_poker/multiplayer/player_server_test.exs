defmodule SuperPoker.Multiplayer.PlayerServerTest do
  use ExUnit.Case

  alias SuperPoker.Multiplayer.HeadsupTableServer
  alias SuperPoker.Multiplayer.TableSup
  alias SuperPoker.Multiplayer.PlayerServer

  @table_config %{
    id: 1001,
    max_players: 2,
    sb: 5,
    bb: 10,
    buyin: 500,
    table: SuperPoker.Multiplayer.HeadsupTableServer,
    rules: SuperPoker.RulesEngine.SimpleRules1v1,
    player: SuperPoker.Multiplayer.PlayerRequestSender
  }

  describe "测试玩家进程PlayerServer与TableServer交互" do
    test "简单二人对战桌基本流程测试" do
      table_id = 8001
      TableSup.start_table(%{@table_config | id: table_id})
      s = HeadsupTableServer.get_state(table_id)
      assert s.p0 == nil
      assert s.p1 == nil
      assert s.table_status == :WAITING

      # 玩家加入
      PlayerServer.start_player("anna")
      PlayerServer.start_player("bob")
      PlayerServer.join_table("anna", table_id, 500)
      PlayerServer.join_table("bob", table_id, 500)
      s = HeadsupTableServer.get_state(table_id)
      assert s.p0 != nil
      assert s.p1 != nil

      # 玩家开始
      PlayerServer.start_game("anna")
      PlayerServer.start_game("bob")
      Process.sleep(200)
      s = PlayerServer.get_state("anna")
      assert [_, _] = s.hole_cards
      s = HeadsupTableServer.get_state(table_id)
      assert s.table.next_action == {:player, {0, [:fold, {:call, 5}, :raise]}}

      # 轮到anna行动
      s = PlayerServer.get_state("anna")
      assert s.bet_actions == [:fold, {:call, 5}, :raise]
      s = PlayerServer.get_state("bob")
      assert s.bet_actions == []

      # # 玩家行动开始
      PlayerServer.player_action("anna", :fold)
    end
  end
end
