# TODO: 明确了通过username的话，就可以定义dummy版本，方便测试了，研究后续到底该咋测试
# TODO: 我现在直接用默认的1001的话，会有所冲突，每个建新的话，如何后继前边的状态呢
# TODO: 尽管有Emacs可以方便插入代码到shell，还是尽量不要那么用，而是通过测试，把代码攒出来
defmodule SuperPoker.GameServer.HeadsupTableServerTest do
  use ExUnit.Case, async: false

  import Hammox
  setup :set_mox_global
  setup :verify_on_exit!

  alias SuperPoker.GameServer.HeadsupTableServer
  alias SuperPoker.GameServer.TableSupervisor

  @table_config %{
    id: 99001,
    max_players: 2,
    sb: 5,
    bb: 10,
    buyin: 500,
    table: SuperPoker.GameServer.HeadsupTableServer,
    rules: SuperPoker.RulesEngine.SimpleRules1v1,
    # FIXME, 这里，不应该定义这种NULL的东西, 而是应该mox并确认被调用到的函数正确参数才对
    player: SuperPoker.PlayerNotify.PlayerRequestNull
  }

  # 只运行一次, 启动一个进程给所有test case用
  setup_all do
    table_id = unique_table_id()

    TableSupervisor.start_table(%{@table_config | id: table_id})
    |> IO.inspect(label: "启动桌子 #{table_id} 结果")

    {:ok, %{table_id: table_id}}
  end

  defp unique_table_id() do
    DateTime.utc_now() |> DateTime.to_unix(:microsecond)
  end

  describe "一组顺序执行的玩家加入并离开牌桌测试" do
    test "单个玩家加入空桌子, 并作为唯一玩家接到所有玩家信息通知", %{table_id: table_id} do
      # 1. 两玩家加入桌子, 通知双方筹码信息
      MockPlayerRequestSender
      |> expect(:notify_players_info, 1, fn ["anna"],
                                            [
                                              %{
                                                username: "anna",
                                                chips: 500,
                                                status: :JOINED
                                              }
                                            ] ->
        :ok
      end)

      assert HeadsupTableServer.join_table(table_id, "anna") == :ok

      # 阻塞调用, 确保notify通知调用完成
      :pong = HeadsupTableServer.ping(table_id)
    end

    test "第二个玩家加入, 通知所有玩家", %{table_id: table_id} do
      MockPlayerRequestSender
      |> expect(:notify_players_info, 1, fn ["anna", "bob"], _ -> :ok end)

      assert HeadsupTableServer.join_table(table_id, "bob") == :ok
      # 阻塞调用, 确保notify通知调用完成
      :pong = HeadsupTableServer.ping(table_id)
    end

    test "玩家点击'开始游戏'", %{table_id: table_id} do
      # 2.1 两玩家开始游戏, 通知双方状态变化
      MockPlayerRequestSender
      |> expect(:notify_players_info, 2, fn ["anna", "bob"], _ -> :ok end)
      # 2.2 通知双方下盲注
      |> expect(:notify_bets_info, 1, fn _all_players, bets_info ->
        IO.inspect(bets_info, label: "MOX BET")
        :ok
      end)
      # 2.3 盲注通知完毕之后 开始发hole cards
      |> expect(:deal_hole_cards, 1, fn "anna", _anna_cards ->
        :ok
      end)
      |> expect(:deal_hole_cards, 1, fn "bob", _bob_cards ->
        :ok
      end)

      assert HeadsupTableServer.start_game(table_id, "anna") == :ok
      :pong = HeadsupTableServer.ping(table_id)

      assert HeadsupTableServer.start_game(table_id, "bob") == :ok
      :pong = HeadsupTableServer.ping(table_id)
    end

    @tag :skip
    test "jixu", %{table_id: table_id} do
      # 3.1 开始anna preflop行动
      # 通知anna可以的操作
      MockPlayerRequestSender
      |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
                                                   "anna",
                                                   [:fold, {:call, 5}, :raise] ->
        :ok
      end)
      # Anna call之后通知所有玩家下注信息更新
      |> expect(:notify_bets_info, 1, fn all, bets_info ->
        IO.inspect(bets_info, label: "MOX BET")
        :ok
      end)
      # 通知下一步bob操作
      |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
                                                   "bob",
                                                   [:fold, :check, :raise] ->
        :ok
      end)

      HeadsupTableServer.player_action_done(table_id, "anna", :call)

      # # 3.2 开始bob preflop行动
      # # 通知所有玩家bob下注
      # MockPlayerRequestSender
      # |> expect(:deal_community_cards, 1, fn ["anna", "bob"], :flop, [_, _, _] -> :ok end)
      # # 通知flop发牌之后下一步该先从bob开始操作了
      # |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
      #                                              "bob",
      #                                              [:fold, :check, :raise] ->
      #   :ok
      # end)
      # # bob check之后更新bets info信息
      # |> expect(:notify_bets_info, 1, fn all, bets_info ->
      #   IO.inspect(bets_info, label: "MOX BET")
      #   :ok
      # end)
      # # 同时, 通知大家下一步该轮到anna行动
      # |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
      #                                              "anna",
      #                                              [:fold, :check, :raise] ->
      #   :ok
      # end)

      # HeadsupTableServer.player_action_done(table_id, "bob", :check)

      Process.sleep(1000)
    end

    # test "玩家加入已有一人桌子, 通知两人玩家信息给两个玩家" do
    #   expect(MockPlayerRequestSender, :notify_players_info, 1, fn _, _ -> :ok end)
    #   table_id = unique_table_id()
    #   TableSupervisor.start_table(%{@table_config | id: table_id})
    #   # FIXME, 这里supervisor似乎异步启动, 如何确保启动成功
    #   s = HeadsupTableServer.get_state(table_id)
    #   assert HeadsupTableServer.join_table(table_id, "anna") == :ok
    #   s = HeadsupTableServer.get_state(table_id)
    #   assert s.p0.username == "anna"
    #   assert s.p1 == nil
    #   assert s.table_status == :WAITING
    # end
  end

  # describe "单挑牌桌测试" do
  #   test "最多只能两个玩家加入" do
  #     expect(MockPlayerRequestSender, :notify_players_info, 2, fn _, _ -> :ok end)
  #     TableSupervisor.start_table(%{@table_config | id: 9001})
  #     s = HeadsupTableServer.get_state(9001)
  #     assert s.p0 == nil
  #     assert s.p1 == nil
  #     assert s.table_status == :WAITING

  #     assert HeadsupTableServer.join_table(9001, "anna") == :ok
  #     s = HeadsupTableServer.get_state(9001)
  #     assert s.p0.username == "anna"
  #     assert s.p1 == nil

  #     assert HeadsupTableServer.join_table(9001, "bob") == :ok
  #     s = HeadsupTableServer.get_state(9001)
  #     assert s.p0.username == "anna"
  #     assert s.p1.username == "bob"

  #     assert HeadsupTableServer.join_table(9001, "catlina") == {:error, :table_full}
  #   end

  #   test "玩家开始牌局" do
  #     TableSupervisor.start_table(%{@table_config | id: 9002})
  #     HeadsupTableServer.join_table(9002, "anna")
  #     HeadsupTableServer.join_table(9002, "bob")

  #     assert HeadsupTableServer.start_game(9002, "anna") == :ok
  #     s = HeadsupTableServer.get_state(9002)
  #     assert s.p0.status == :READY
  #     assert s.p1.status == :JOINED
  #     assert s.table_status == :WAITING

  #     assert HeadsupTableServer.start_game(9002, "bob") == :ok
  #     s = HeadsupTableServer.get_state(9002)
  #     assert s.p0.status == :READY
  #     assert s.p1.status == :READY
  #     assert s.table_status == :RUNNING
  #     assert s.table != nil
  #   end

  #   test "简单一方fold迅速完整完成一局对战并验证筹码更新" do
  #     TableSupervisor.start_table(%{@table_config | id: 9003})
  #     HeadsupTableServer.join_table(9003, "anna")
  #     HeadsupTableServer.join_table(9003, "bob")
  #     HeadsupTableServer.start_game(9003, "anna")
  #     HeadsupTableServer.start_game(9003, "bob")
  #     s = HeadsupTableServer.get_state(9003)
  #     assert s.table.next_action == {:player, {0, [:fold, {:call, 5}, :raise]}}
  #     HeadsupTableServer.player_action_done(9003, "anna", :fold)
  #     s = HeadsupTableServer.get_state(9003)
  #     assert s.table.next_action == {:winner, 1, %{0 => 495, 1 => 505}}
  #     # 确认最终玩家筹码正确设置
  #     assert s.p0.chips == 495
  #     assert s.p1.chips == 505
  #     # 桌子回到等待状态
  #     assert s.table_status == :WAITING
  #   end

  #   test "普通call以及check验证后续发牌轮" do
  #     TableSupervisor.start_table(%{@table_config | id: 9004})
  #     HeadsupTableServer.join_table(9004, "anna")
  #     HeadsupTableServer.join_table(9004, "bob")
  #     HeadsupTableServer.start_game(9004, "anna")
  #     HeadsupTableServer.start_game(9004, "bob")

  #     # preflop轮下注
  #     HeadsupTableServer.player_action_done(9004, "anna", :call)
  #     HeadsupTableServer.player_action_done(9004, "bob", :check)

  #     # 牌桌完成自动发牌flop
  #     s = HeadsupTableServer.get_state(9004)
  #     assert s.table.current_street == :flop
  #     assert s.table.next_action == {:player, {1, [:fold, :check, :raise]}}
  #     HeadsupTableServer.player_action_done(9004, "bob", :check)
  #     HeadsupTableServer.player_action_done(9004, "anna", :check)

  #     # 牌桌完成发牌turn
  #     s = HeadsupTableServer.get_state(9004)
  #     assert s.table.current_street == :turn
  #     assert s.table.next_action == {:player, {1, [:fold, :check, :raise]}}
  #     HeadsupTableServer.player_action_done(9004, "bob", :check)
  #     HeadsupTableServer.player_action_done(9004, "anna", :check)

  #     # 牌桌完成发牌turn
  #     s = HeadsupTableServer.get_state(9004)
  #     assert s.table.current_street == :river
  #     assert s.table.next_action == {:player, {1, [:fold, :check, :raise]}}
  #     HeadsupTableServer.player_action_done(9004, "bob", :check)
  #     HeadsupTableServer.player_action_done(9004, "anna", :check)

  #     # 最终牌局结束
  #     s = HeadsupTableServer.get_state(9004)
  #     assert s.table_status == :WAITING
  #     # 确定玩家回到等待状态
  #     assert s.p0.status == :JOINED
  #   end

  #   test "发牌流程测试" do
  #     TableSupervisor.start_table(%{@table_config | id: 9005})
  #     HeadsupTableServer.join_table(9005, "anna")
  #     HeadsupTableServer.join_table(9005, "bob")
  #     HeadsupTableServer.start_game(9005, "anna")
  #     HeadsupTableServer.start_game(9005, "bob")
  #     s = HeadsupTableServer.get_state(9005)
  #     assert s.deck != []
  #     assert s.community_cards == []
  #     assert [_, _] = cards0 = s.player_cards[0]
  #     assert [_, _] = cards1 = s.player_cards[1]
  #     HeadsupTableServer.player_action_done(9005, "anna", :call)
  #     HeadsupTableServer.player_action_done(9005, "bob", :check)
  #     # 发出flop
  #     s = HeadsupTableServer.get_state(9005)
  #     assert Enum.count(s.community_cards) == 3
  #     # 玩家手牌不变
  #     assert s.player_cards[0] == cards0
  #     assert s.player_cards[1] == cards1
  #     HeadsupTableServer.player_action_done(9005, "bob", :check)
  #     HeadsupTableServer.player_action_done(9005, "anna", :check)

  #     # 发出turn
  #     s = HeadsupTableServer.get_state(9005)
  #     assert Enum.count(s.community_cards) == 4
  #     HeadsupTableServer.player_action_done(9005, "bob", :check)
  #     HeadsupTableServer.player_action_done(9005, "anna", :check)

  #     # 发出river
  #     s = HeadsupTableServer.get_state(9005)
  #     assert Enum.count(s.community_cards) == 5
  #     HeadsupTableServer.player_action_done(9005, "bob", :check)
  #     HeadsupTableServer.player_action_done(9005, "anna", :check)
  #     s = HeadsupTableServer.get_state(9005)
  #     assert s.table_status == :WAITING
  #   end

  #   @tag :skip
  #   # TODO
  #   test "玩家只有在牌局没开始情况下离开" do
  #     assert 1 == 2
  #   end
  # end
end
