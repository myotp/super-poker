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
    <button phx-click="join-table-1001">Join table 1001</button>
    """
  end

  def handle_event("join-table-1001", _, socket) do
    {:noreply, push_redirect(socket, to: ~p"/table?id=1001")}
  end
end
