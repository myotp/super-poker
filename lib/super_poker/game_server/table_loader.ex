defmodule SuperPoker.GameServer.TableLoader do
  use GenServer
  require Logger

  @moduledoc """
  这里模拟读取所有游戏牌桌配置信息
  """

  # ================= API ======================
  def all_table_info() do
    GenServer.call(__MODULE__, :all_table_info)
  end

  # ============= GenServer对应回调函数 ================
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(nil) do
    {:ok, nil, {:continue, :do_load_table_info}}
  end

  @impl GenServer
  def handle_continue(:do_load_table_info, _) do
    Logger.info("加载牌桌信息")
    table_info = fetch_table_info()
    {:noreply, table_info}
  end

  @impl GenServer
  def handle_call(:all_table_info, _from, table_info) do
    {:reply, {:ok, table_info}, table_info}
  end

  defp fetch_table_info() do
    [
      %{
        id: 1001,
        max_players: 2,
        sb: 5,
        bb: 10,
        buyin: 500,
        table: SuperPoker.GameServer.HeadsupTableServer,
        player: SuperPoker.PlayerNotify.PlayerRequestSender,
        rules: SuperPoker.RulesEngine.SimpleRules1v1
      }
      | random_table_info(50)
    ]
  end

  defp random_table_info(n) do
    2..(n + 1)
    |> Enum.map(fn n ->
      sb = Enum.random([1, 2, 5, 10, 20])

      %{
        id: 1000 + n,
        max_players: Enum.random([2, 5, 6, 8]),
        sb: sb,
        bb: sb * 2,
        buyin: Enum.random([500, 1000, 2000, 3000, 5000]),
        table: SuperPoker.GameServer.HeadsupTableServer,
        player: SuperPoker.PlayerNotify.PlayerRequestSender,
        rules: SuperPoker.RulesEngine.SimpleRules1v1
      }
    end)
  end
end
