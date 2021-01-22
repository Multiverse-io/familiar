defmodule Familiar.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:animals) do
      add :species, :string, null: false
      add :age, :integer, null: false
      add :alive, :boolean, null: false

      timestamps()
    end
  end
end
