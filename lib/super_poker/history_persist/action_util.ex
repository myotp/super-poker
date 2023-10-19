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

  defp action_to_attrs(:fold), do: %{action: :fold, amount: 0}
  defp action_to_attrs(:check), do: %{action: :check, amount: 0}
  defp action_to_attrs({:call, amount}), do: %{action: :call, amount: amount}
  defp action_to_attrs({:raise, amount}), do: %{action: :raise, amount: amount}

  def recreate_table_and_player_actions(sp_game) do
    orders = create_action_order_for_all_streets(sp_game)
    streets = [:preflop, :flop, :turn, :river]

    streets
    |> Enum.map(fn street -> extract_street(sp_game, street, orders) end)
    |> Enum.concat()
  end

  defp create_player_action(%{action: :check}, username) do
    {:player, username, :check}
  end

  defp create_player_action(%{action: action, amount: amount}, username) do
    {:player, username, {action, amount}}
  end

  defp extract_street(sp_game, street, orders) do
    [username1, username2] = orders[street]

    actions1 =
      extract_user_actions_for_street(sp_game, username1, street)
      |> Enum.map(fn action_from_db -> create_player_action(action_from_db, username1) end)

    actions2 =
      extract_user_actions_for_street(sp_game, username2, street)
      |> Enum.map(fn action_from_db -> create_player_action(action_from_db, username2) end)

    player_actions = merge_two_lists_one_by_one(actions1, actions2)

    case street do
      :preflop ->
        player_actions

      _ ->
        [
          {:deal, street, street_community_cards(sp_game.community_cards, street)}
          | player_actions
        ]
    end
  end

  defp street_community_cards(all_community_cards, street) do
    all_community_cards
    |> String.split(" ", trim: true)
    |> Enum.take(num_community_cards_for_street(street))
    |> Enum.join(" ")
  end

  defp num_community_cards_for_street(:flop), do: 3
  defp num_community_cards_for_street(:turn), do: 4
  defp num_community_cards_for_street(:river), do: 5

  defp extract_user_actions_for_street(sp_game, username, street) do
    m = Enum.find(sp_game.player_actions, fn a -> a.username == username end)
    get_in(m, [Access.key(street)])
  end

  # 不太好用Enum.zip因为理论上每个人操作数量不一定完全相同
  def merge_two_lists_one_by_one(l1, l2) do
    l1 = Enum.zip(l1, Stream.iterate(1, &(&1 + 2)))
    l2 = Enum.zip(l2, Stream.iterate(2, &(&1 + 2)))

    (l1 ++ l2)
    |> Enum.sort_by(fn {_, index} -> index end)
    |> Enum.map(fn {value, _} -> value end)
  end

  defp create_action_order_for_all_streets(sp_game) do
    button_player =
      Enum.find(sp_game.players, &(&1.pos == sp_game.button_pos))
      |> get_in([Access.key(:username)])

    bb_player =
      Enum.find(sp_game.players, &(&1.pos != sp_game.button_pos))
      |> get_in([Access.key(:username)])

    %{
      preflop: [button_player, bb_player],
      flop: [bb_player, button_player],
      turn: [bb_player, button_player],
      river: [bb_player, button_player]
    }
  end
end
