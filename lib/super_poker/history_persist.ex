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

  def load_hand_history(game_id, username) do
    {:todo, :hand_history, game_id, username}
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
