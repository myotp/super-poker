defmodule SuperPokerWeb.LobbyLive do
  use SuperPokerWeb, :live_view

  alias SuperPoker.GameServer.TableManager

  def mount(_, _, socket) do
    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    sort_by = (params["sort_by"] || "table_id") |> String.to_atom()
    sort_order = (params["sort_order"] || "asc") |> String.to_atom()

    options = %{
      sort_by: sort_by,
      sort_order: sort_order
    }

    all_tables = TableManager.all_table_info(options)

    {:noreply, assign(socket, tables: all_tables, options: options)}
  end

  def render(assigns) do
    ~H"""
    <div id="lobby">
      <div class="wrapper">
        <table>
          <thead>
            <tr>
              <th class="table-id">
                <.sort_link sort_by={:table_id} options={@options}>
                  Table
                </.sort_link>
              </th>
              <th class="buyin">
                <.sort_link sort_by={:buyin} options={@options}>
                  Buyin
                </.sort_link>
              </th>
              <th class="players">
                <.sort_link sort_by={:max_players} options={@options}>
                  Players
                </.sort_link>
              </th>
              <th class="bb">
                <.sort_link sort_by={:bb} options={@options}>
                  SB/BB
                </.sort_link>
              </th>
              <th class=""></th>
            </tr>
          </thead>
          <tbody>
            <tr :for={table <- @tables}>
              <td class="table-id"><%= table.table_id %></td>
              <td class="buyin"><%= table.buyin %></td>
              <td class="players"><%= table.max_players %></td>
              <td class="bb"><%= table.sb %>/<%= table.bb %></td>
              <td>
                <button phx-click="join-table" phx-value-table_id={table.table_id}>JOIN</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  def handle_event("join-table", %{"table_id" => table_id}, socket) do
    {:noreply, push_redirect(socket, to: ~p"/table?#{[id: table_id]}")}
  end

  defp sort_link(assigns) do
    ~H"""
    <.link patch={
      ~p"/lobby?#{%{sort_by: @sort_by, sort_order: next_sort_order(@options.sort_order)}}"
    }>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp next_sort_order(sort_order) do
    case sort_order do
      :asc -> :desc
      :desc -> :asc
    end
  end
end
