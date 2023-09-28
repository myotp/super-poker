defmodule SuperPokerWeb.LobbyLive do
  use SuperPokerWeb, :live_view

  def mount(_, _, socket) do
    IO.puts("LobbyLive mount/3 called")
    IO.inspect(socket.assigns, label: "Lobby assigns")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Welcome <%= @current_user.email %></h1>
    """
  end
end
