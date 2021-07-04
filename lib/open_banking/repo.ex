defmodule OpenBanking.Repo do
  use Ecto.Repo,
    otp_app: :open_banking,
    adapter: Ecto.Adapters.Postgres
end
