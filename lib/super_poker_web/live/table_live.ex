defmodule SuperPokerWeb.TableLive do
  use SuperPokerWeb, :live_view

  alias SuperPoker.Core.Card
  alias SuperPoker.Player

  # FIXME: 从/login页面通过session传过来
  @username "lvcas"

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
      |> assign(pot: 0)
      |> assign(in_gaming: false)
      |> assign(my_username: @username)
      |> assign(oppo_username: "WAITING")
      |> assign(my_chips_left: 500)
      |> assign(oppo_chips_left: 0)
      |> assign(my_bet: 0)
      |> assign(oppo_bet: 0)
      |> assign(my_hole_cards: [])
      |> assign(oppo_hole_cards: [])
      |> assign(my_status: :JOINED)
      |> assign(oppo_status: :EMPTY)
      |> assign(
        community_cards: [
          # %Card{rank: 3, suit: :hearts},
          # %Card{rank: 11, suit: :spades},
          # %Card{rank: 12, suit: :clubs},
          # %Card{rank: 13, suit: :diamonds},
          # %Card{rank: 1, suit: :spades}
        ]
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Hello, game</h1>

    <div class="pot-info">
      POT: <%= @pot %><br /> Community Cards:
      <div class="mt-4 grid grid-cols-5 gap-4">
        <%= for card <- @community_cards do %>
          <img
            src={card_to_image(card)}
            alt={inspect(card)}
            class="rounded-lg border-2 border-black-500"
          />
        <% end %>
      </div>
    </div>

    <table class="min-w-full border-separate border-spacing-y-3 text-center">
      <thead>
        <tr class="mb-4">
          <th class="px-4 py-2 bg-gray-300">Player</th>
          <th class="px-4 py-2 bg-gray-300">Chips</th>
          <th class="px-4 py-2 bg-gray-300">Bet</th>
          <th class="px-4 py-2 bg-gray-300">Cards</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td class={player_status(@my_status)}><%= @my_username %></td>
          <td class="border px-4 py-2"><%= @my_chips_left %></td>
          <td class="border px-4 py-2"><%= @my_bet %></td>
          <td class="border w-1/3">
            <div class="grid grid-cols-2 gap-1">
              <%= for card <- @my_hole_cards do %>
                <img
                  src={card_to_image(card)}
                  alt={inspect(card)}
                  class="rounded-lg border-2 border-black-500"
                />
              <% end %>
            </div>
          </td>
        </tr>
        <tr>
          <td class={player_status(@oppo_status)}><%= @oppo_username %></td>
          <td class="border px-4 py-2"><%= @oppo_chips_left %></td>
          <td class="border px-4 py-2"><%= @oppo_bet %></td>
          <td class="border px-4 py-2"><%= inspect(@oppo_hole_cards) %></td>
        </tr>
      </tbody>
    </table>

    <div :if={not @in_gaming} class="start-game-button">
      <button phx-click="start-game">Start Game</button>
    </div>

    <div :if={@in_gaming} class="grid grid-cols-4 gap-4">
      <div class="game-action-button">
        <button phx-click="game-action-check">check</button>
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
    </div>
    """
  end

  defp card_to_image(%Card{rank: rank, suit: suit}) do
    "/images/poker/#{suit_file_name(suit)}-#{rank_file_name(rank)}.svg"
  end

  defp suit_file_name(:diamonds), do: "DIAMOND"
  defp suit_file_name(:hearts), do: "HEART"
  defp suit_file_name(:spades), do: "SPADE"
  defp suit_file_name(:clubs), do: "CLUB"

  defp rank_file_name(11), do: "11-JACK"
  defp rank_file_name(12), do: "12-QUEEN"
  defp rank_file_name(13), do: "13-KING"
  # ACE
  defp rank_file_name(14), do: "1"
  defp rank_file_name(n), do: Integer.to_string(n)

  def handle_event("start-game", _, socket) do
    Player.start_game(@username)
    {:noreply, socket}
  end

  def handle_event("game-action-check", _, socket) do
    Player.player_action(my_username(socket), :check)
    {:noreply, socket}
  end

  def handle_event("game-action-call", _, socket) do
    Player.player_action(my_username(socket), :call)
    {:noreply, socket}
  end

  def handle_event("game-action-fold", _, socket) do
    Player.player_action(my_username(socket), :fold)
    {:noreply, socket}
  end

  defp my_username(socket), do: socket.assigns.username

  defp player_status(:EMPTY), do: "username-empty"
  defp player_status(:JOINED), do: "username-joined"
  defp player_status(:READY), do: "username-ready"

  def handle_info({:players_info, players_info}, socket) do
    IO.inspect(players_info, label: "LiveView收到玩家信息更新")
    socket = update_players_info(socket, players_info)
    {:noreply, socket}
  end

  def handle_info({:update_bets, bets_info}, socket) do
    IO.inspect(bets_info, label: "收到下注更新信息")

    me = socket.assigns.my_username
    oppo = socket.assigns.oppo_username

    IO.inspect(me, label: "my name")
    IO.inspect(oppo, label: "对手姓名")

    IO.inspect(bets_info[me], label: "我的下注")

    IO.inspect(bets_info[me].chips_left, label: "我的筹码余额")

    socket =
      socket
      |> assign(:in_gaming, true)
      |> assign(:pot, bets_info.pot)
      |> assign(:my_chips_left, bets_info[me].chips_left)
      |> assign(:oppo_chips_left, bets_info[oppo].chips_left)
      |> assign(:my_bet, bets_info[me].current_street_bet)
      |> assign(:oppo_bet, bets_info[oppo].current_street_bet)
      |> assign(:bets_info, bets_info)

    {:noreply, socket}
  end

  def handle_info({:hole_cards, cards}, socket) do
    socket = assign(socket, :my_hole_cards, cards)
    {:noreply, socket}
  end

  def handle_info({:community_cards, _street, cards}, socket) do
    socket = assign(socket, :community_cards, socket.assigns.community_cards ++ cards)
    {:noreply, socket}
  end

  def handle_info({:winner, winner, chips}, socket) do
    me = socket.assigns.my_username
    oppo = socket.assigns.oppo_username

    IO.inspect(winner, label: "收到服务器结果赢家")

    socket =
      socket
      |> assign(:in_gaming, false)
      |> assign(:my_chips_left, chips[me])
      |> assign(:my_bet, 0)
      |> assign(:oppo_chips_left, chips[oppo])
      |> assign(:oppo_bet, 0)
      |> assign(:my_status, :JOINED)
      |> assign(:oppo_status, :JOINED)

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

    if is_nil(oppo) do
      socket
      |> assign(:my_chips_left, me.chips)
      |> assign(:my_status, me.status)
    else
      socket
      |> assign(:my_chips_left, me.chips)
      |> assign(:my_status, me.status)
      |> assign(:oppo_username, oppo.username)
      |> assign(:oppo_chips_left, oppo.chips)
      |> assign(:oppo_status, oppo.status)
    end
  end
end
