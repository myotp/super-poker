defmodule SuperPoker.IrcDataset.TableTest do
  use ExUnit.Case

  alias SuperPoker.IrcDataset.Table

  import ExUnit.CaptureIO

  describe "parse/1" do
    test "桌子对战到最后5张公共牌" do
      table_str = "965102715   5 22814  8  2/160   2/280   2/360    2/440    9h Kc 6d Js 5c"

      assert %Table{
               game_id: 965_102_715,
               blind: 5,
               pot_after_preflop: 160,
               pot_after_flop: 280,
               pot_after_turn: 360,
               pot_after_river: 440,
               community_cards: "9H KC 6D JS 5C"
             } == Table.parse(table_str)
    end

    test "桌子中途所有人fold结束" do
      table_str = "965102895   5 22819  7  2/50    0/0     0/0      1/70     Ts 5c 6s"

      assert %Table{
               game_id: 965_102_895,
               blind: 5,
               pot_after_preflop: 50,
               pot_after_flop: 0,
               pot_after_turn: 0,
               pot_after_river: 70,
               community_cards: "TS 5C 6S"
             } == Table.parse(table_str)
    end

    test "尚未发出公共牌即结束" do
      table_str = "965103647   5 22840  6  0/0     0/0     0/0      1/50     "

      assert %Table{
               game_id: 965_103_647,
               blind: 5,
               pot_after_preflop: 0,
               pot_after_flop: 0,
               pot_after_turn: 0,
               pot_after_river: 50,
               community_cards: ""
             } == Table.parse(table_str)
    end

    test "出错数据返回nil" do
      table_str = "965103647   5 22840  6  0/0     0/0  "

      parse_fun = fn ->
        assert Table.parse(table_str) == nil
      end

      assert capture_io(parse_fun) =~ "HELP"
    end
  end
end
