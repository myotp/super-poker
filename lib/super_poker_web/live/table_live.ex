defmodule SuperPokerWeb.TableLive do
  use SuperPokerWeb, :live_view

  alias SuperPoker.Player

  def mount(_, _, socket) do
    IO.inspect(self(), label: "MOUNT <PID>")

    if connected?(socket) do
      # FIXME: 这里，强行就先启动这个玩家
      Player.start_player("lv")
      Player.join_table("lv", 1001, 500)
    end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Hello, game</h1>
    """
  end

  def handle_info({:players_info, players_info}, socket) do
    IO.inspect(players_info, label: "LiveView收到玩家信息更新")
    {:noreply, socket}
  end
end
