defmodule SuperPoker.IrcDataset.IrcGameTest do
  use SuperPoker.DataCase

  alias SuperPoker.Repo
  alias SuperPoker.IrcDataset.Table
  alias SuperPoker.IrcDataset.GamePlayers
  alias SuperPoker.IrcDataset.PlayerActions
  alias SuperPoker.IrcDataset.IrcPlayerActions
  alias SuperPoker.IrcDataset.IrcTable
  alias SuperPoker.IrcDataset.IrcGame

  describe "存储game->players到DB" do
    test "存储来自hroster数据到数据库" do
      game_players = %GamePlayers{
        game_id: 10001,
        num_players: 2,
        players: ["Anna", "Bob"]
      }

      assert {:ok, %IrcGame{id: id}} = IrcGame.save_game_players(game_players)

      assert %IrcGame{game_id: 10001, num_players: 2, players: ["Anna", "Bob"]} =
               Repo.get!(IrcGame, id)
    end

    test "重复的game_id简单忽略方便任务重复运行" do
      game_players = %GamePlayers{
        game_id: 10002,
        num_players: 2,
        players: ["Anna", "Bob"]
      }

      game_players_2 = %GamePlayers{
        game_players
        | num_players: 3,
          players: ["Anna", "Bob", "Lucas"]
      }

      assert {:ok, %IrcGame{id: id1}} = IrcGame.save_game_players(game_players)

      # 重复game_id的插入简单忽略即可, 方便导入任务中途出错重复运行
      assert {:ok, %IrcGame{id: nil}} = IrcGame.save_game_players(game_players_2)

      assert %IrcGame{game_id: 10002, num_players: 2, players: ["Anna", "Bob"]} =
               Repo.get!(IrcGame, id1)
    end
  end

  describe "作为整合模块读取game全部信息" do
    test "读取game与两玩家操作以及牌桌pot公共牌等所有信息" do
      game_players = %GamePlayers{
        game_id: 8001,
        num_players: 2,
        players: ["Anna", "Bob"]
      }

      {:ok, %IrcGame{id: id}} = IrcGame.save_game_players(game_players)

      %PlayerActions{
        username: "Anna",
        game_id: 8001,
        num_players: 2,
        pos: 1,
        preflop: "Bc",
        flop: "k",
        turn: "f",
        bankroll: 500,
        total_bet: 20,
        winnings: 0
      }
      |> IrcPlayerActions.save_player_actions()

      %PlayerActions{
        username: "Bob",
        game_id: 8001,
        num_players: 2,
        pos: 2,
        preflop: "Bk",
        flop: "k",
        turn: nil,
        bankroll: 500,
        total_bet: 20,
        winnings: 40
      }
      |> IrcPlayerActions.save_player_actions()

      %Table{
        game_id: 8001,
        blind: 2,
        pot_after_preflop: 10,
        pot_after_flop: 20,
        pot_after_turn: 30,
        pot_after_river: 40,
        community_cards: "AH KH QH JH TH"
      }
      |> IrcTable.save_table()

      assert irc_game = %IrcGame{id: ^id} = IrcGame.load_game_with_player_actions(8001)

      assert irc_game.players_actions != []
      assert irc_game.table != nil

      assert ["Anna", "Bob"] ==
               get_in(irc_game.players_actions, [Access.all(), Access.key(:username)])
               |> Enum.sort()

      assert irc_game.table.blind == 2
    end
  end
end
