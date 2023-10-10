# TODO: 明确了通过username的话，就可以定义dummy版本，方便测试了，研究后续到底该咋测试
# TODO: 我现在直接用默认的1001的话，会有所冲突，每个建新的话，如何后继前边的状态呢
# TODO: 尽管有Emacs可以方便插入代码到shell，还是尽量不要那么用，而是通过测试，把代码攒出来
# TODO: 因为这个模块测试的内容顺序依赖, 必须async false且--seed 0的方式按顺序运行每一个test case
defmodule SuperPoker.GameServer.HeadsupTableServerTest do
  use ExUnit.Case, async: false

  # 这个模块的测试必须只能顺序运行, 需要--seed 0的时候才行
  @moduletag :seed0

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
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
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
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
        assert %{pot: 20} = bets_info
        :ok
      end)
      # 3.4 发flop公共牌
      |> expect(:deal_community_cards, 1, fn ["anna", "bob"], :flop, cards ->
        IO.inspect(cards, label: "公共牌3张发出来了")
        :ok
      end)
      # 3.5 发完一轮公共牌之后, 下注移入pot, 更新发给玩家
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
        assert bets_info == %{
                 :pot => 20,
                 "anna" => %{chips_left: 490, current_street_bet: 0},
                 "bob" => %{chips_left: 490, current_street_bet: 0}
               }

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

    test "flop之后首先bob行动check", %{table_id: table_id} do
      MockPlayerRequestSender
      # bob下注之后, 广播下注最新信息给所有玩家
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
        assert bets_info == %{
                 :pot => 20,
                 "anna" => %{chips_left: 490, current_street_bet: 0},
                 "bob" => %{chips_left: 490, current_street_bet: 0}
               }

        :ok
      end)
      # 通知下一个该anna行动
      |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
                                                   "anna",
                                                   [:fold, :check, :raise] ->
        :ok
      end)

      HeadsupTableServer.player_action_done(table_id, "bob", :check)
      :pong = HeadsupTableServer.ping(table_id)
    end

    test "flop后位玩家anna也check之后发牌", %{table_id: table_id} do
      MockPlayerRequestSender
      # bob下注之后, 广播下注最新信息给所有玩家
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
        assert bets_info == %{
                 :pot => 20,
                 "anna" => %{chips_left: 490, current_street_bet: 0},
                 "bob" => %{chips_left: 490, current_street_bet: 0}
               }

        :ok
      end)
      # 之后发牌
      |> expect(:deal_community_cards, 1, fn ["anna", "bob"], :turn, [%Card{}] ->
        :ok
      end)
      # 下注信息再次广播出去
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
        assert bets_info == %{
                 :pot => 20,
                 "anna" => %{chips_left: 490, current_street_bet: 0},
                 "bob" => %{chips_left: 490, current_street_bet: 0}
               }

        :ok
      end)
      # 之后轮到bob行动
      |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
                                                   "bob",
                                                   [:fold, :check, :raise] ->
        :ok
      end)

      HeadsupTableServer.player_action_done(table_id, "anna", :check)
      :pong = HeadsupTableServer.ping(table_id)
    end

    test "turn轮bob先行动check", %{table_id: table_id} do
      MockPlayerRequestSender
      # bob下注之后, 广播下注最新信息给所有玩家
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
        assert bets_info == %{
                 :pot => 20,
                 "anna" => %{chips_left: 490, current_street_bet: 0},
                 "bob" => %{chips_left: 490, current_street_bet: 0}
               }

        :ok
      end)
      # 之后轮到anna行动
      |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
                                                   "anna",
                                                   [:fold, :check, :raise] ->
        :ok
      end)

      HeadsupTableServer.player_action_done(table_id, "bob", :check)
      :pong = HeadsupTableServer.ping(table_id)
    end

    test "turn轮anna加注raise", %{table_id: table_id} do
      MockPlayerRequestSender
      # anna加注之后, 广播下注最新信息给所有玩家
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
        assert bets_info == %{
                 :pot => 20,
                 "anna" => %{chips_left: 390, current_street_bet: 100},
                 "bob" => %{chips_left: 490, current_street_bet: 0}
               }

        :ok
      end)
      # 之后轮到bob行动
      |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
                                                   "bob",
                                                   [:fold, {:call, 100}, :raise] ->
        :ok
      end)

      HeadsupTableServer.player_action_done(table_id, "anna", {:raise, 100})
      :pong = HeadsupTableServer.ping(table_id)
    end

    test "turn轮bob面对加注call", %{table_id: table_id} do
      MockPlayerRequestSender
      # bob跟注之后, 广播下注最新信息给所有玩家
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
        assert bets_info == %{
                 # FIXME: 这里pot应该是20此时的双方100应该还没进pot才对
                 :pot => 220,
                 "anna" => %{chips_left: 390, current_street_bet: 100},
                 "bob" => %{chips_left: 390, current_street_bet: 100}
               }

        :ok
      end)
      # 之后发牌
      |> expect(:deal_community_cards, 1, fn ["anna", "bob"], :river, [%Card{}] ->
        :ok
      end)
      # 下注信息再次广播出去
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
        assert bets_info == %{
                 :pot => 220,
                 "anna" => %{chips_left: 390, current_street_bet: 0},
                 "bob" => %{chips_left: 390, current_street_bet: 0}
               }

        :ok
      end)
      # 之后轮到bob行动
      |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
                                                   "bob",
                                                   [:fold, :check, :raise] ->
        :ok
      end)

      HeadsupTableServer.player_action_done(table_id, "bob", :call)
      :pong = HeadsupTableServer.ping(table_id)
    end

    test "river轮bob先行动check", %{table_id: table_id} do
      MockPlayerRequestSender
      # bob下注之后, 广播下注最新信息给所有玩家
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
        assert bets_info == %{
                 :pot => 220,
                 "anna" => %{chips_left: 390, current_street_bet: 0},
                 "bob" => %{chips_left: 390, current_street_bet: 0}
               }

        :ok
      end)
      # 之后轮到anna行动
      |> expect(:notify_player_todo_actions, 1, fn ["anna", "bob"],
                                                   "anna",
                                                   [:fold, :check, :raise] ->
        :ok
      end)

      HeadsupTableServer.player_action_done(table_id, "bob", :check)
      :pong = HeadsupTableServer.ping(table_id)
    end

    test "river轮anna简单check判定牌局过程", %{table_id: table_id} do
      MockPlayerRequestSender
      # anna下注之后, 广播下注最新信息给所有玩家
      |> expect(:notify_bets_info, 1, fn ["anna", "bob"], bets_info ->
        assert bets_info == %{
                 :pot => 220,
                 "anna" => %{chips_left: 390, current_street_bet: 0},
                 "bob" => %{chips_left: 390, current_street_bet: 0}
               }

        :ok
      end)
      # 牌局通知结果
      |> expect(:notify_winner_result, 1, fn ["anna", "bob"],
                                             winner,
                                             chips,
                                             {_type,
                                              %{
                                                "anna" => _anna_hole_cards,
                                                "bob" => _bob_hole_cards
                                              }, _win5, _lose5} ->
        case winner do
          "anna" ->
            assert chips["anna"] == 610
            assert chips["bob"] == 390

          "bob" ->
            assert chips["anna"] == 390
            assert chips["bob"] == 610

          nil ->
            assert chips["anna"] == 500
            assert chips["bob"] == 500
        end

        :ok
      end)

      HeadsupTableServer.player_action_done(table_id, "anna", :check)
      :pong = HeadsupTableServer.ping(table_id)
    end
  end

  describe "一方玩家fold的情景测试" do
    test "anna fold情景测试" do
      table_id = unique_table_id()

      TableSupervisor.start_table(%{@table_config | id: table_id})
      |> IO.inspect(label: "启动桌子 #{table_id} 结果")

      :pong = HeadsupTableServer.ping(table_id)

      MockPlayerRequestSender
      # 其它的通知前边test case已经覆盖到了, 这里就简单stub能工作就好
      |> stub(:notify_players_info, fn _, _ -> :ok end)
      |> stub(:notify_bets_info, fn _, _ -> :ok end)
      |> stub(:deal_hole_cards, fn _, _ -> :ok end)
      |> stub(:notify_player_todo_actions, fn _, _, _ -> :ok end)
      # 这里重点是测试在一个玩家fold的情况下, 最终结果只更新筹码信息不显示双方手牌
      |> expect(:notify_winner_result, fn _, "bob", %{"anna" => 495, "bob" => 505}, nil -> :ok end)

      HeadsupTableServer.join_table(table_id, "anna")
      HeadsupTableServer.join_table(table_id, "bob")
      HeadsupTableServer.start_game(table_id, "anna")
      HeadsupTableServer.start_game(table_id, "bob")
      # 玩家anna直接fold牌局结束
      HeadsupTableServer.player_action_done(table_id, "anna", :fold)
      :pong = HeadsupTableServer.ping(table_id)
    end
  end
end
