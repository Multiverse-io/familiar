defmodule Viewex.Repo.Migrations.UpdateViews do
  use Ecto.Migration
  use Viewex

  def change do
    replace_view :chickens, version: 2, revert: 1
  end
end
