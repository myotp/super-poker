defmodule SuperPoker.IrcDataset.GamePlayersTest do
  use ExUnit.Case

  alias SuperPoker.IrcDataset.GamePlayers

  import ExUnit.CaptureIO

  describe "parse/1" do
    test "二人玩家到最后showhands" do
      str = "965102895  3 Anna Bob Lucas"

      assert GamePlayers.parse(str) == %GamePlayers{
               game_id: 965_102_895,
               num_players: 3,
               players: ["Anna", "Bob", "Lucas"]
             }
    end

    test "错误数据的情况" do
      invalid_players_str = "965102895  3 Anna Bob"

      parse_fun = fn ->
        assert GamePlayers.parse(invalid_players_str) == nil
      end

      assert capture_io(parse_fun) =~ "HELP"
    end
  end
end
