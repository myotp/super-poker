# TODO: 明确了通过username的话，就可以定义dummy版本，方便测试了，研究后续到底该咋测试
# TODO: 我现在直接用默认的1001的话，会有所冲突，每个建新的话，如何后继前边的状态呢
# TODO: 尽管有Emacs可以方便插入代码到shell，还是尽量不要那么用，而是通过测试，把代码攒出来
# TODO: 因为这个模块测试的内容顺序依赖, 必须async false且--seed 0的方式按顺序运行每一个test case
defmodule SuperPoker.GameServer.HeadsupTableServerTest do
  use ExUnit.Case, async: false

  import Hammox
  setup :set_mox_global
  setup :verify_on_exit!

  alias SuperPoker.GameServer.HeadsupTableServer
  alias SuperPoker.GameServer.TableSupervisor
  alias SuperPoker.Core.Card

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
    # FIXME: HOWO?
    # 固定顺序, 因为Test Case之间依赖顺序
    # ExUnit.configure(seed: 0)
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
    end

    test "第二个玩家加入, 通知所有玩家", %{table_id: table_id} do
      MockPlayerRequestSender
      |> expect(:notify_players_info, 1, fn ["anna", "bob"], players_info ->
        assert Enum.sort(players_info) ==
                 [
                   %{username: "anna", chips: 500, status: :JOINED},
                   %{username: "bob", chips: 500, status: :JOINED}
                 ]
                 |> Enum.sort()

        :ok
      end)

      assert HeadsupTableServer.join_table(table_id, "bob") == :ok
    end

    test "第一个玩家点击'开始游戏'", %{table_id: table_id} do
      # 2.1 两玩家开始游戏, 通知双方状态变化
      MockPlayerRequestSender
      |> expect(:notify_players_info, 1, fn ["anna", "bob"], players_info ->
        assert Enum.sort(players_info) ==
                 [
                   %{username: "anna", chips: 500, status: :READY},
                   %{username: "bob", chips: 500, status: :JOINED}
                 ]
                 |> Enum.sort()

        :ok
      end)

      assert HeadsupTableServer.start_game(table_id, "anna") == :ok
      :pong = HeadsupTableServer.ping(table_id)
    end

    test "第二个玩家开始, 此时游戏正式开始", %{table_id: table_id} do
      # 2.1 两玩家开始游戏, 通知双方状态变化
      MockPlayerRequestSender
      |> expect(:notify_players_info, 1, fn ["anna", "bob"], players_info ->
        assert Enum.sort(players_info) ==
                 [
                   %{username: "anna", chips: 500, status: :READY},
                   %{username: "bob", chips: 500, status: :READY}
                 ]
                 |> Enum.sort()

        :ok
      end)

      # 2.2 通知双方下盲注
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
        assert bets_info == %{
                 :pot => 0,
                 "anna" => %{chips_left: 495, current_street_bet: 5},
                 "bob" => %{chips_left: 490, current_street_bet: 10}
               }

        :ok
      end)
      # 2.3 盲注通知完毕之后 开始发hole cards
      |> expect(:deal_hole_cards, 1, fn "anna", [%Card{}, %Card{}] ->
        :ok
      end)
      |> expect(:deal_hole_cards, 1, fn "bob", [%Card{}, %Card{}] ->
        :ok
      end)
      # 2.4 发牌之后通知下一步轮到anna行动
      |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
                                                   "anna",
                                                   [:fold, {:call, 5}, :raise] ->
        :ok
      end)

      assert HeadsupTableServer.start_game(table_id, "bob") == :ok

      # 阻塞调用, 让GenServer完成handle_continue确保mox的函数都被执行到
      :pong = HeadsupTableServer.ping(table_id)
    end

    test "preflop阶段anna先行动", %{table_id: table_id} do
      # 3.1 开始anna preflop行动
      MockPlayerRequestSender
      # Anna call之后通知所有玩家下注信息更新
      |> expect(:notify_bets_info, 1, fn all, bets_info ->
        assert bets_info == %{
                 :pot => 0,
                 "anna" => %{chips_left: 490, current_street_bet: 10},
                 "bob" => %{chips_left: 490, current_street_bet: 10}
               }

        :ok
      end)
      # 通知下一步bob操作
      |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
                                                   "bob",
                                                   [:fold, :check, :raise] ->
        :ok
      end)

      HeadsupTableServer.player_action_done(table_id, "anna", :call)
      :pong = HeadsupTableServer.ping(table_id)
    end

    test "preflop阶段回到bob行动", %{table_id: table_id} do
      # 3.2 开始bob preflop行动
      MockPlayerRequestSender
      # 3.3 bob check之后更新bets info信息
      |> expect(:notify_bets_info, 1, fn all, bets_info ->
        IO.inspect(bets_info, label: "MOX BET")
        :ok
      end)
      # 3.4 发flop公共牌
      |> expect(:deal_community_cards, 1, fn ["anna", "bob"], :flop, cards ->
        IO.inspect(cards, label: "公共牌3张发出来了")
        :ok
      end)
      # 3.5 发完一轮公共牌之后, 下注移入pot, 更新发给玩家
      |> expect(:notify_bets_info, 1, fn all, bets_info ->
        IO.inspect(bets_info, label: "MOX BET")
        :ok
      end)
      # 3.6通知flop发牌之后下一步该先从bob开始操作了
      |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
                                                   "bob",
                                                   [:fold, :check, :raise] ->
        :ok
      end)

      HeadsupTableServer.player_action_done(table_id, "bob", :check)
      :pong = HeadsupTableServer.ping(table_id)
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
