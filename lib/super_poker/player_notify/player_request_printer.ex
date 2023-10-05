# 这个模块用来辅助开发调试阶段使用，可以打印输入内容，方便开发调试
defmodule SuperPoker.PlayerNotify.PlayerRequestPrinter do
  alias SuperPoker.PlayerNotify.PlayerNotifierApi
  @behaviour PlayerNotifierApi

  @impl PlayerNotifierApi
  def notify_players_info(_, _) do
    # 一开始的时候没有此代码, 改造了之后, 加入behaviour之后就可以看出来缺失了
    :ok
  end

  def notify_bets_info(all_players, bets) do
    Enum.each(all_players, fn player ->
      IO.puts("通知玩家 #{player} 下注 #{inspect(bets)}")
    end)
  end

  def notify_blind_bet(all_players, blinds) do
    Enum.each(all_players, fn player ->
      IO.puts("通知玩家 #{player} 大小盲 #{inspect(blinds)}")
    end)
  end

  def deal_hole_cards(username, cards) do
    IO.puts("通知玩家 #{username} 发到手牌 #{inspect(cards)}")
  end

  def notify_player_todo_actions(all_players, current_action_username, actions) do
    Enum.each(all_players, fn player ->
      IO.puts("通知玩家 #{player} 当前等待 #{current_action_username} 可选操作 #{inspect(actions)}")
    end)
  end

  # 一方fold，另一方自动获胜，不用比牌
  def notify_winner_result(all_players, winner, player_chips, nil) do
    Enum.each(all_players, fn player ->
      IO.puts("通知玩家 #{player} 赢家为 #{winner} 大伙筹码更新 #{inspect(player_chips)}")
    end)
  end

  # 双方摊牌打平
  def notify_winner_result(all_players, nil, players_chips, {type, _hole_cards, win5, lose5}) do
    Enum.each(all_players, fn player ->
      IO.puts("""
       通知玩家 #{player} 最终两人打平 手牌类型 #{type}
       玩家1 #{inspect(win5)} 玩家2 #{inspect(lose5)}
      大伙筹码更新 #{inspect(players_chips)}
      """)
    end)
  end

  # 正常一方获胜，另一方失败
  def notify_winner_result(all_players, winner, players_chips, {type, _hole_cards, win5, lose5}) do
    Enum.each(all_players, fn player ->
      IO.puts("""
       通知玩家 #{player} 最终胜利玩家 #{winner} 手牌类型 #{type}
       赢家 #{inspect(win5)} 输家 #{inspect(lose5)}
      大伙筹码更新 #{inspect(players_chips)}
      """)
    end)
  end

  def deal_community_cards(all_players, street, cards) do
    Enum.each(all_players, fn player ->
      IO.puts("通知玩家 #{player} 当前发牌轮 #{street} 发牌 #{inspect(cards)}")
    end)
  end
end
