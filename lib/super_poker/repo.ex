defmodule SuperPoker.Repo do
  use Ecto.Repo,
    otp_app: :super_poker,
    adapter: Ecto.Adapters.Postgres
end
