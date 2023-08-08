defmodule SuperPokerWeb.TableLive do
  use SuperPokerWeb, :live_view

  alias SuperPoker.Player

  # FIXME: 从/login页面通过session传过来
  @username "lv-client"

  def mount(_, _, socket) do
    IO.inspect(self(), label: "MOUNT <PID>")

    if connected?(socket) do
      # FIXME: 这里，强行就先启动这个玩家
      Player.start_player(@username)
      Player.join_table(@username, 1001, 500)
    end

    socket =
      socket
      |> assign(username: @username)
      |> assign(me: nil)
      |> assign(oppo: nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Hello, game</h1>
    <div class="players_info">
      <div class="player">
        <%= if @me do %>
          <%= @me.username %> <%= @me.chips %> <%= @me.status %>
        <% else %>
          等待中...
        <% end %>
      </div>

      <div class="player">
        <%= if @oppo do %>
          <%= @oppo.username %> <%= @oppo.chips %> <%= @oppo.status %>
        <% else %>
          等待中...
        <% end %>
      </div>
    </div>
    <div class="table_actions">
      <button phx-click="start-game">Start Game</button>
    </div>
    """
  end

  def handle_event("start-game", _, socket) do
    Player.start_game(@username)
    {:noreply, socket}
  end

  def handle_info({:players_info, players_info}, socket) do
    IO.inspect(players_info, label: "LiveView收到玩家信息更新")
    socket = update_players_info(socket, players_info)
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    IO.inspect(msg, label: "========>>>>> TODO")
    {:noreply, socket}
  end

  defp update_players_info(socket, players_info) do
    me = Enum.find(players_info, fn m -> m.username == socket.assigns.username end)
    IO.inspect(me, label: "玩家信息之自己")
    oppo = Enum.find(players_info, nil, fn m -> m.username != socket.assigns.username end)
    IO.inspect(oppo, label: "玩家信息之对手")
    assign(socket, me: me, oppo: oppo)
  end
end
