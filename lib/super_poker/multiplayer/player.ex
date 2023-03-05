defmodule SuperPoker.Multiplayer.Player do
  # 这里，一个简单的printer打印内容，方便观察调试自己的服务器部分
  # @player SuperPoker.Multiplayer.PlayerRequestPrinter
  @player SuperPoker.Multiplayer.PlayerRequestSender

  # 来自服务器端的调用部分
  defdelegate notify_blind_bet(players, blind), to: @player
  defdelegate deal_hole_cards(username, cards), to: @player
  defdelegate notify_deal_cards(all_players, street, cards), to: @player
  defdelegate notify_player_action(all_players, current_action_username, actions), to: @player
  defdelegate notify_winner_result(all_players, winner, player_chips, hand_result), to: @player
end
