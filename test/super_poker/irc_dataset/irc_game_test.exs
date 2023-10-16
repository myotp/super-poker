defmodule SuperPoker.IrcDataset.IrcGameTest do
  use SuperPoker.DataCase

  alias SuperPoker.Repo
  alias SuperPoker.IrcDataset.GamePlayers
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
end
