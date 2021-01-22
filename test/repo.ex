defmodule Familiar.Repo do
  use Ecto.Repo,
    otp_app: :familiar,
    adapter: Ecto.Adapters.Postgres
end
