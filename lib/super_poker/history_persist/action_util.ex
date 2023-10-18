defmodule SuperPoker.HistoryPersist.ActionUtil do
  # 转换内存牌局对战历史中的用户actions数据成Ecto参数
  def prepare_player_actions_attrs(actions, username) do
    do_actions(actions, :preflop, username, %{username: username})
  end

  defp do_actions([], _, _, attrs) do
    attrs
  end

  defp do_actions([{:player, username, action} | rest], street, username, attrs) do
    attrs = update_in(attrs[street], &((&1 || []) ++ [action_to_attrs(action)]))
    do_actions(rest, street, username, attrs)
  end

  defp do_actions([{:deal, new_street, _} | rest], _current_street, username, attrs) do
    do_actions(rest, new_street, username, attrs)
  end

  defp do_actions([_ | rest], street, username, attrs) do
    do_actions(rest, street, username, attrs)
  end

  defp action_to_attrs(:fold), do: %{action: "fold", amount: 0}
  defp action_to_attrs(:check), do: %{action: "check", amount: 0}
  defp action_to_attrs({:call, amount}), do: %{action: "call", amount: amount}
  defp action_to_attrs({:raise, amount}), do: %{action: "raise", amount: amount}
end
