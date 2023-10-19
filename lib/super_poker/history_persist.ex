defmodule SuperPoker.HistoryPersist do
  require Logger
  alias SuperPoker.HandHistory.HandHistory
  alias SuperPoker.HistoryPersist.SpGame
  alias SuperPoker.HistoryPersist.SpPlayerAction
  alias SuperPoker.HistoryPersist.ActionUtil

  require Logger

  def save_hand_history(%HandHistory{} = hh) do
    hh = move_player_hole_cards(hh)

    case SpGame.save_game_history(Map.from_struct(hh)) do
      {:ok, %SpGame{id: game_id}} ->
        save_player_actions(hh, game_id)

        {:ok, game_id}
    end
  end

  def load_hand_history(game_id) do
    sp_game = SpGame.read_game_history_from_db(game_id)
    actions = ActionUtil.recreate_table_and_player_actions(sp_game)
    hole_cards = extract_hole_cards(sp_game)

    %HandHistory{
      game_id: sp_game.id,
      start_time: sp_game.start_time,
      sb_amount: sp_game.sb_amount,
      bb_amount: sp_game.bb_amount,
      button_pos: sp_game.button_pos,
      community_cards: sp_game.community_cards,
      hole_cards: hole_cards,
      players: sp_game.players |> Enum.map(fn p -> Map.take(p, [:pos, :username, :chips]) end),
      blinds: sp_game.blinds |> Enum.map(fn b -> Map.take(b, [:username, :amount]) end),
      actions: actions
    }
  end

  defp extract_hole_cards(sp_game) do
    sp_game.players
    |> Enum.map(fn p -> {p.username, p.hole_cards} end)
    |> Map.new()
  end

  defp move_player_hole_cards(hh) do
    players_with_hole_cards =
      Enum.map(hh.players, fn %{username: username} = player_data ->
        hole_cards = hh.hole_cards[username]
        Map.put(player_data, :hole_cards, hole_cards)
      end)

    %HandHistory{hh | players: players_with_hole_cards}
  end

  defp save_player_actions(hh, game_id) do
    usernames = get_in(hh, [Access.key(:players), Access.all(), :username])

    usernames
    |> Enum.each(fn username ->
      player_actions_attrs = ActionUtil.prepare_player_actions_attrs(hh.actions, username)

      case SpPlayerAction.save_player_actions(game_id, player_actions_attrs) do
        {:ok, _} ->
          :ok

        {:error, reason} ->
          Logger.error("FAIL to save player actions for #{username} error: #{inspect(reason)}")
      end
    end)
  end
end
