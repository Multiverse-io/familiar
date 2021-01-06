defmodule ViewexTest do
  use ExUnit.Case
  use Ecto.Migration
  alias Ecto.Migration.Runner
  alias Viewex.Repo

  setup context do
    Repo.start_link()
    direction = Map.get(context, :direction, :forward)

    log = %{level: false, sql: false}

    reset!()

    {:ok, runner} =
      Runner.start_link(
        {self(), Repo, Repo.config(), __MODULE__, direction, :up, log}
      )

    runner = Runner.metadata(runner, %{})

    {:ok, runner: runner}
  end

  describe "create_view" do
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

    @tag direction: :backward
    test "can revert create view" do
      Viewex.create_view(:horses, version: 1)
      flush()

      refute view_exists?("horses")
    end
  end

  defp get_view_def(view_name) do
    %{rows: [[definition]]} = query!("SELECT pg_get_viewdef('#{view_name}'::regclass, true)")
    definition
  end

  defp view_exists?(view_name) do
    %{rows: [[result]]} = query!("SELECT to_regclass('public.#{view_name}')")
    result
  end

  defp reset! do
    query!("DROP SCHEMA public CASCADE")
    query!("CREATE SCHEMA public")
    query!("""
    CREATE TABLE animals (
      species varchar(255) NOT NULL,
      age integer NOT NULL,
      alive boolean NOT NULL
    )
    """)
    query!("""
    CREATE VIEW horses AS
    SELECT * from animals
    WHERE species = 'horse'
    """)
  end

  defp query!(sql) do
    Ecto.Adapters.SQL.query!(Repo, sql, [], log: false)
  end
end
