defmodule SuperPoker.Multiplayer.Player do
  def notify_blind_bet(all_players, blinds) do
    Enum.each(all_players, fn player ->
      IO.puts("通知玩家 #{player} 大小盲 #{inspect(blinds)}")
    end)
  end

  def notify_player_action(all_players, current_action_username, actions) do
    Enum.each(all_players, fn player ->
      IO.puts("通知玩家 #{player} 当前等待 #{current_action_username} 可选操作 #{inspect(actions)}")
    end)
  end

  def notify_winner_result(all_players, winner, players_chips) do
    Enum.each(all_players, fn player ->
      IO.puts("通知玩家 #{player} 最终胜利玩家 #{winner} 大伙筹码更新 #{inspect(players_chips)}")
    end)
  end

  def notify_deal_cards(all_players, street, cards) do
    Enum.each(all_players, fn player ->
      IO.puts("通知玩家 #{player} 当前发牌轮 #{street} 发牌 #{inspect(cards)}")
    end)
  end
end
