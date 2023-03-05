defmodule SuperPoker.Multiplayer.PlayerSup do
  use DynamicSupervisor
  require Logger

  # =================== Public API =====================
  def start_player(username) do
    DynamicSupervisor.start_child(__MODULE__, username)
  end

  # ============= DynamicSupervisor 回调部分 =============
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
