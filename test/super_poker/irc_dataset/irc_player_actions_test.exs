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

      assert [
               %IrcPlayerActions{
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
               }
             ] = Repo.all(IrcPlayerActions)
    end

    test "重复的username+game_id报错" do
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

      # 第二次覆盖
      assert {:ok, %IrcPlayerActions{pos: 2}} =
               IrcPlayerActions.save_player_actions(%{player_actions | pos: 2})
    end
  end
end
