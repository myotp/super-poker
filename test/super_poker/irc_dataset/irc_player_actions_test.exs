defmodule SuperPoker.IrcDataset.IrcPlayerActionsTest do
  use SuperPoker.DataCase

  alias SuperPoker.Repo
  alias SuperPoker.IrcDataset.PlayerActions
  alias SuperPoker.IrcDataset.IrcPlayerActions

  describe "写入" do
    test "读取irc" do
      player_actions = %PlayerActions{
        username: "Jia",
        game_id: 1_010_105_892,
        num_players: 2,
        pos: 1,
        preflop: "Bc",
        flop: "k",
        turn: "f",
        bankroll: 500,
        total_bet: 20,
        winnings: 0
      }

      IrcPlayerActions.save_player_actions(player_actions)

      assert %IrcPlayerActions{
               username: "Jia",
               game_id: 1_010_105_892,
               num_players: 2,
               pos: 1,
               preflop: "Bc",
               flop: "k",
               turn: "f",
               bankroll: 500,
               total_bet: 20,
               winnings: 0,
               river: nil,
               hole_cards: nil
             } = Repo.get_by(IrcPlayerActions, username: "Jia", game_id: 1_010_105_892)
    end

    test "重复的username+game_id简单忽略便于导入数据可以反复执行" do
      player_actions = %PlayerActions{
        username: "Anna",
        game_id: 9001,
        num_players: 2,
        pos: 1,
        preflop: "Bc",
        flop: "k",
        turn: "f",
        bankroll: 500,
        total_bet: 20,
        winnings: 0
      }

      # 第一次插入成功
      assert {:ok, %IrcPlayerActions{pos: 1}} =
               IrcPlayerActions.save_player_actions(player_actions)

      # 第二次简单忽略
      assert {:ok, %IrcPlayerActions{pos: 222}} =
               IrcPlayerActions.save_player_actions(%{player_actions | pos: 222})

      # 实际数据库中仍为原来的值
      assert %IrcPlayerActions{pos: 1} =
               Repo.get_by(IrcPlayerActions, username: "Anna", game_id: 9001)
    end
  end
end
