use Mix.Config

config :viewex,
  ecto_repos: [Viewex.Repo]

config :viewex, Viewex.Repo,
  username: "postgres",
  password: "postgres",
  database: "viewex_test",
  hostname: System.get_env("PGHOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
