defmodule Familiar.Repo.Migrations.UpdateViews do
  use Ecto.Migration
  use Familiar

  def change do
    update_view :chickens, version: 2, revert: 1, materialized: true
    update_function :mix, version: 2, revert: 1
  end
end
