defmodule SuperPoker.GameServer.TableManager do
  use GenServer

  defmodule State do
    defstruct all_tables: []
  end

  def all_table_info(options) do
    GenServer.call(__MODULE__, {:all_table_info, options})
  end

  def register_table(table_config) do
    GenServer.call(__MODULE__, {:new_table_config, table_config})
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    {:ok, %State{}}
  end

  @impl GenServer
  def handle_call(
        {:all_table_info, %{sort_by: sort_by, sort_order: order}},
        _from,
        %State{all_tables: tables} = state
      ) do
    tables = Enum.sort_by(tables, &Map.get(&1, sort_by), order)
    {:reply, tables, state}
  end

  def handle_call({:new_table_config, table_config}, _from, %State{all_tables: tables} = state) do
    {:reply, :ok, %State{state | all_tables: [table_config | tables]}}
  end
end
