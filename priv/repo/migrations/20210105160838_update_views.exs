defmodule Familiar.Repo.Migrations.UpdateViews do
  use Ecto.Migration
  use Familiar

  def change do
    replace_view :chickens, version: 2, revert: 1
  end
end
