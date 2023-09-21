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
      |> assign(in_gaming: false)
      |> assign(bets_info: %{})
      |> assign(hole_cards: [])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Hello, game</h1>
    <div id="poker-game-table">
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
      <div class="start-game-button">
        <button phx-click="start-game">Start Game</button>
      </div>
    </div>

    <%= if @in_gaming do %>
      <div>
        POT: 0
      </div>

      <div>
        <%= @me.username %> 当前街: <%= @bets_info[@me.username].current_street_bet %> 总剩余: <%= @bets_info[
          @me.username
        ].chips_left %>
      </div>

      <div>
        <%= @oppo.username %> 当前街: <%= @bets_info[@oppo.username].current_street_bet %> 总剩余: <%= @bets_info[
          @oppo.username
        ].chips_left %>
      </div>

      <%!-- FIXME: 这里不能嵌套if吗
       <%= if @hole_cards != [] %>
          我的手牌<%= @hole_cards %>
      <% end %> --%>
      <div>
        我的手牌 <%= inspect(@hole_cards) %>
      </div>

      <div class="game-action-button">
        <button phx-click="game-action-fold">fold</button>
      </div>
      <div class="game-action-button">
        <button phx-click="game-action-call">call</button>
      </div>
      <div class="game-action-button">
        <button phx-click="game-action-raise">raise</button>
      </div>
    <% end %>
    """
  end

  def handle_event("start-game", _, socket) do
    Player.start_game(@username)
    {:noreply, socket}
  end

  def handle_event("game-action-fold", _, socket) do
    Player.player_action(my_username(socket), :fold)
    {:noreply, socket}
  end

  defp my_username(socket), do: socket.assigns.username

  def handle_info({:players_info, players_info}, socket) do
    IO.inspect(players_info, label: "LiveView收到玩家信息更新")
    socket = update_players_info(socket, players_info)
    {:noreply, socket}
  end

  def handle_info({:update_bets, bets_info}, socket) do
    IO.inspect(bets_info, label: "收到下注更新信息")

    socket =
      socket
      |> assign(:in_gaming, true)
      |> assign(:bets_info, bets_info)

    {:noreply, socket}
  end

  def handle_info({:hole_cards, cards}, socket) do
    socket = assign(socket, :hole_cards, cards)
    {:noreply, socket}
  end

  def handle_info({:winner, winner}, socket) do
    IO.inspect(winner, label: "赢家")
    socket = assign(socket, in_gaming: false)
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
