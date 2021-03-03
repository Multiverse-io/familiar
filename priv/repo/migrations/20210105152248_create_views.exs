defmodule Familiar.Repo.Migrations.CreateViews do
  use Ecto.Migration
  use Familiar

  def change do
    create_view "chickens", version: 1, materialized: true
    create_function "mix", version: 1
  end
end
