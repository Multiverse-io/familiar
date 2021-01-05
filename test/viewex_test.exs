defmodule ViewexTest do
  use ExUnit.Case
  use Ecto.Migration
  alias Ecto.Migration.Runner
  alias Viewex.Repo

  setup do
    Repo.start_link()

    {:ok, runner} =
      Runner.start_link(
        {self(), Repo, Repo.config(), __MODULE__, :forward, :up, %{level: false, sql: false}}
      )

    runner = Runner.metadata(runner, %{})

    Viewex.drop_view_if_exists(:chickens)

    create_if_not_exists table(:animals) do
      add(:species, :string, null: false)
      add(:age, :integer, null: false)
      add(:alive, :boolean, null: false)

      timestamps()
    end

    flush()

    {:ok, runner: runner}
  end

  test "can create view v1" do
    Viewex.create_view(:chickens, version: 1)
    flush()

    view = get_view_def("chickens")
    assert view =~ "WHERE animals.species::text = 'chicken'::text;"
  end

  test "can create view v2" do
    Viewex.create_view(:chickens, version: 2)
    flush()

    view = get_view_def("chickens")
    assert view =~ "WHERE animals.species::text = 'chicken'::text AND animals.alive = true;"
  end

  defp get_view_def(view_name) do
    %{rows: [[definition]]} =
      Ecto.Adapters.SQL.query!(Repo, "select pg_get_viewdef('#{view_name}'::regclass, true)", [], log: false)

    definition
  end
end
