defmodule SuperPoker.Multiplayer.TelnetSessionServer do
  use GenServer
  require Logger
  alias SuperPoker.Multiplayer.TelnetProtocol
  alias SuperPoker.Multiplayer.PlayerServer

  defmodule State do
    defstruct username: "",
              current_turn: nil,
              socket: nil
  end

  def start_link(socket) do
    Logger.info("#{inspect(self())} #{__MODULE__} 回调start_link")
    # [GOOD-OTP] 这里是动态进程，不再注册名字
    GenServer.start_link(__MODULE__, socket)
  end

  @impl GenServer
  def init(socket) do
    Logger.info("#{inspect(self())} #{__MODULE__} 回调init(#{inspect(socket)})")
    {:ok, %State{socket: socket}, {:continue, :welcome}}
  end

  # 最开始的未登陆状态
  @impl GenServer
  def handle_continue(:welcome, state) do
    :gen_tcp.send(state.socket, "==== WELCOME TO Super-Poker GAME CENTER ====\r\n")
    {:noreply, state}
  end

  @impl GenServer
  # [GOOD-OTP] 这里，不同的退出shutdown原因，后续可以配合另外的session进程，体会用法
  def handle_info({:tcp_closed, _socket}, state) do
    Logger.info("#{inspect(self())} #{__MODULE__} 客户端已关闭，自己即将关闭...")
    {:stop, {:shutdown, :client_tcp_closed}, state}
  end

  # 主要的处理用户请求的地方
  def handle_info({:tcp, socket, input}, state) do
    case handle_tcp_request(socket, input, state) do
      {:ok, :exit} ->
        # [GOOD-OTP] 后续结合相关进程实践，只有这种用户自己表明logout情况下，才去关闭内部用户进程，否则都保活，支持重连
        {:stop, {:shutdown, :client_logout}, state}

      {:ok, :ping} ->
        {:noreply, state}

      {:ok, new_state} ->
        {:noreply, new_state}
    end
  end

  def handle_info(msg, state) do
    IO.inspect(msg, label: "TODO实际处理要发送给玩家的信息")
    {:noreply, state}
  end

  defp handle_tcp_request(socket, input, state) do
    case TelnetProtocol.parse(String.trim(input)) do
      {:ok, :exit} ->
        :gen_tcp.send(socket, "BYE BYE!\r\n")
        :gen_tcp.close(socket)
        {:ok, :exit}

      {:ok, req} ->
        # [FIXME] 这里参考Design Elixir OTP用更加地道的Elixir方式去写
        {response, new_state} = do_handle_request(state, req)
        :gen_tcp.send(socket, [response, "\r\n"])
        {:ok, new_state}

      {:error, reason} ->
        :gen_tcp.send(socket, ["ERROR: #{inspect(reason)}\r\n"])
        {:ok, state}
    end
  end

  # ============= 主要处理客户端发送来的请求部分 ============
  # 这里，模拟login，当前的话，默认全部成功
  # [GOOD-OTP] 这里，真正启动一个针对这个Telnet进程的一个代理session进程
  defp do_handle_request(state, :new_line) do
    {"", state}
  end

  defp do_handle_request(state, {:login, {username, _password}}) do
    # TODO: 这里，确保进程启动，可能是保活，用户断线，已经启动过了，重连，也可能是新来新启动
    {:ok, _} = PlayerServer.start_player(username)
    # 之前为了方便测试，把订阅与启动分为了两步走了
    PlayerServer.register_client(username)
    {"WELCOME #{username}!", %{state | username: username}}
  end

  defp do_handle_request(%State{username: username} = state, {:join, table_id}) do
    case PlayerServer.join_table(username, table_id, 500) do
      :ok ->
        {"JOINED TABLE #{table_id}", state}

      {:error, reason} ->
        {"FAILED TO JOIN TABLE reason=#{reason}", state}
    end
  end

  defp do_handle_request(%State{username: username} = state, :start_game) do
    case PlayerServer.start_game(username) do
      :ok ->
        {"WAITING TO START", state}

      {:error, reason} ->
        {"FAILED TO START GAME reason=#{reason}", state}
    end
  end
end
