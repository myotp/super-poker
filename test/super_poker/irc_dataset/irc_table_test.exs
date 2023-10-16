defmodule SuperPoker.IrcDataset.IrcTableTest do
  use SuperPoker.DataCase

  alias SuperPoker.Repo
  alias SuperPoker.IrcDataset.Table
  alias SuperPoker.IrcDataset.IrcTable

  describe "写入" do
    test "将hdb文件内容写入PostgreSQL数据库" do
      table = %Table{
        game_id: 5001,
        blind: 10,
        pot_after_preflop: 20,
        pot_after_flop: 80,
        pot_after_turn: 200,
        pot_after_river: 1000,
        community_cards: "AH KH QH JH TH"
      }

      assert {:ok, _} = IrcTable.save_table(table)

      assert %IrcTable{
               game_id: 5001,
               blind: 10,
               pot_after_preflop: 20,
               pot_after_flop: 80,
               pot_after_turn: 200,
               pot_after_river: 1000,
               community_cards: "AH KH QH JH TH"
             } =
               Repo.get_by(IrcTable, game_id: 5001)
    end

    test "重复game_id简单忽略" do
      table = %Table{
        game_id: 5001,
        blind: 10,
        pot_after_preflop: 20,
        pot_after_flop: 80,
        pot_after_turn: 200,
        pot_after_river: 1000,
        community_cards: "AH KH QH JH TH"
      }

      assert {:ok, _} = IrcTable.save_table(table)
      # 第二次重复PK写入简单忽略即可
      assert {:ok, _} = IrcTable.save_table(%Table{table | blind: 20})
      # 验证内容不变
      assert %IrcTable{blind: 10} = Repo.get_by(IrcTable, game_id: 5001)
    end

    test "在公共牌尚未发出即结束" do
      table = %Table{
        game_id: 5002,
        blind: 5,
        pot_after_preflop: 20,
        pot_after_flop: 0,
        pot_after_turn: 0,
        pot_after_river: 20,
        community_cards: ""
      }

      assert {:ok, _} = IrcTable.save_table(table)
      assert %IrcTable{blind: 5, community_cards: ""} = Repo.get_by(IrcTable, game_id: 5002)
    end
  end
end
