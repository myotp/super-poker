defmodule SuperPokerWeb.LobbyLive do
  use SuperPokerWeb, :live_view

  alias SuperPoker.GameServer.TableManager

  def mount(_, _, socket) do
    IO.puts("LobbyLive mount/3 called")
    IO.inspect(socket.assigns, label: "Lobby assigns")
    all_tables = TableManager.all_table_info()
    {:ok, assign(socket, :tables, all_tables)}
  end

  def render(assigns) do
    ~H"""
    <h1>Welcome <%= @current_user.email %></h1>
    <button phx-click="join-table-1001" phx-value-table_id="8888">Join table 1001</button>
    <div>
      <table class="min-w-full border-separate border-spacing-y-3 text-center">
        <thead>
          <tr class="mb-4">
            <th class="px-4 py-2 bg-gray-300">ID</th>
            <th class="px-4 py-2 bg-gray-300">buyin</th>
            <th class="px-4 py-2 bg-gray-300">players</th>
            <th class="px-4 py-2 bg-gray-300">sb/bb</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={table <- @tables}>
            <td><%= table.table_id %></td>
            <td><%= table.buyin %></td>
            <td><%= table.max_players %></td>
            <td><%= table.bb %></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  def handle_event("join-table-1001", d, socket) do
    IO.inspect(d, label: "button额外数据")
    {:noreply, push_redirect(socket, to: ~p"/table?id=1001")}
  end
end
