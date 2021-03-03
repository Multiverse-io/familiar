use Mix.Config

config :familiar, Familiar.Repo,
  username: "postgres",
  password: "postgres",
  database: "familiar_test",
  hostname: System.get_env("PGHOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
