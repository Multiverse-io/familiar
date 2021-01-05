defmodule Viewex.Repo.Migrations.CreateViews do
  use Ecto.Migration
  use Viewex

  def change do
    create_view "chickens", version: 1
  end
end
