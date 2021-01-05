defmodule Viewex.Repo do
  use Ecto.Repo,
    otp_app: :viewex,
    adapter: Ecto.Adapters.Postgres
end
