defmodule SuperPoker.HistoryPersist.SpGameTest do
  use SuperPoker.DataCase

  alias SuperPoker.HistoryPersist.SpGame
  #  alias SuperPoker.Repo

  describe "save" do
    test "简单存储" do
      game_history_attrs = %{
        start_time: NaiveDateTime.from_iso8601!("1999-12-31 12:59:59"),
        button_pos: 2,
        sb_amount: 0.05,
        bb_amount: 0.10,
        community_cards: "AH KH QH JH TH"
      }

      assert {:ok,
              %SpGame{
                id: game_id,
                start_time: ~N[1999-12-31 12:59:59],
                button_pos: 2,
                sb_amount: 0.05,
                bb_amount: 0.1,
                community_cards: "AH KH QH JH TH"
              }} =
               SpGame.save_game_history(game_history_attrs)

      assert game_id > 200_000_000_000

      assert %SpGame{
               id: ^game_id,
               start_time: ~N[1999-12-31 12:59:59],
               button_pos: 2,
               sb_amount: 0.05,
               bb_amount: 0.1,
               community_cards: "AH KH QH JH TH"
             } =
               Repo.get(SpGame, game_id)
    end
  end
end
