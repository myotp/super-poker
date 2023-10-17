defmodule SuperPoker.HistoryPersist do
  alias SuperPoker.HandHistory.HandHistory

  def save_hand_history(%HandHistory{} = hh) do
    {:ok, hh}
  end

  def load_hand_history(game_id, username) do
    {:todo, :hand_history, game_id, username}
  end
end
