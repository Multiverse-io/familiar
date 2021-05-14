# Familiar

[![Build Status](https://github.com/Multiverse-io/familiar/workflows/CI/badge.svg)](https://github.com/Multiverse-io/familiar/actions) [![Hex.pm](https://img.shields.io/hexpm/v/familiar.svg)](https://hex.pm/packages/familiar)

An Elixir library to manage database views, functions and triggers - your database's familiars.

Creating a view is as simple as defining it in SQL and then creating it in a migration.

``` sql
-- priv/repo/views/active_users_v1.sql
SELECT * FROM users
WHERE users.active
```

There's also a mix task to create a view with an incrementing version number.

```
mix familiar.gen.view active_users
```

``` elixir
# priv/repo/migrations/create_users_view.exs

defmodule Sample.Repo.Migrations.CreateViews do
  use Ecto.Migration
  use Familiar

  def change do
    create_view "active_users", version: 1
  end
end
```

To update a view, simply create a new view definition and replace it
``` sql
-- priv/repo/views/active_users_v2.sql
SELECT * FROM users
WHERE users.deactivated_at IS NULL
```

``` elixir
# priv/repo/migrations/create_users_view.exs
  def change do
    replace_view "active_users", version: 2, revert: 1
  end
```


## Installation

Familiar can be installed by adding `familiar` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:familiar, "~> 0.1.0"}
  ]
end
```
