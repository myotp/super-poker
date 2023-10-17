defmodule SuperPoker.HistoryPersist.SpGameTest do
  use SuperPoker.DataCase

  alias SuperPoker.HistoryPersist.SpGame
  alias SuperPoker.HistoryPersist.SpGamePlayer
  alias SuperPoker.HistoryPersist.Query
  alias SuperPoker.Repo

  describe "save" do
    test "简单存储" do
      game_history_attrs = %{
        start_time: NaiveDateTime.from_iso8601!("1999-12-31 12:59:59"),
        button_pos: 2,
        sb_amount: 0.05,
        bb_amount: 0.10,
        community_cards: "AH KH QH JH TH",
        players: [
          %{pos: 1, username: "Anna", chips: 10.0, hole_cards: "3C 2C"},
          %{pos: 2, username: "Lucas", chips: 15.0, hole_cards: "3D 2D"}
        ]
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
             } = Repo.get(SpGame, game_id)

      assert %SpGamePlayer{
               username: "Anna",
               pos: 1
             } = Query.find_game_player(game_id, "Anna")

      assert %SpGamePlayer{
               username: "Lucas",
               pos: 2
             } = Query.find_game_player(game_id, "Lucas")

      assert Query.find_game_player(game_id, "NONONO") == nil
      assert Query.find_game_player(509_080, "Anna") == nil
    end
  end
end
