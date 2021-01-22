defmodule FamiliarTest do
  use ExUnit.Case
  use Ecto.Migration
  alias Ecto.Migration.Runner
  alias Familiar.Repo

  setup do
    Repo.start_link()

    query!("DROP SCHEMA public CASCADE")
    query!("CREATE SCHEMA public")
    query!("""
    CREATE TABLE animals (
      species varchar(255) NOT NULL,
      age integer NOT NULL,
      alive boolean NOT NULL
    )
    """)

    {:ok, []}
  end

  describe "create_view" do
    test "can create view v1" do
      forwards(fn ->
        Familiar.create_view(:chickens, version: 1)
      end)

      view = get_view_def("chickens")
      assert view =~ "WHERE animals.species::text = 'chicken'::text;"
    end

    test "can create view v2" do
      forwards(fn ->
        Familiar.create_view(:chickens, version: 2)
      end)

      view = get_view_def("chickens")
      assert view =~ "WHERE animals.species::text = 'chicken'::text AND animals.alive = true;"
    end

    test "can revert create view" do
      forwards(fn ->
        Familiar.create_view(:chickens, version: 1)
      end)

      backwards(fn ->
        Familiar.create_view(:chickens, version: 1)
      end)

      refute view_exists?("chickens")
    end
  end

  describe "update_view" do
    test "can update view" do
      forwards(fn ->
        Familiar.create_view(:chickens, version: 1)
        Familiar.update_view(:chickens, version: 2)
      end)

      view = get_view_def("chickens")
      assert view =~ "WHERE animals.species::text = 'chicken'::text AND animals.alive = true;"
    end

    test "can revert updating view" do
      forwards(fn ->
        Familiar.create_view(:chickens, version: 2)
      end)

      backwards(fn ->
        Familiar.update_view(:chickens, version: 2, revert: 1)
      end)

      view = get_view_def("chickens")
      assert view =~ "WHERE animals.species::text = 'chicken'::text;"
    end
  end

  describe "replace_view" do
    test "can replace a view" do
      forwards(fn ->
        Familiar.create_view(:chickens, version: 1)
        Familiar.replace_view(:chickens, version: 2)
      end)

      view = get_view_def("chickens")
      assert view =~ "WHERE animals.species::text = 'chicken'::text AND animals.alive = true;"
    end

    test "can revert replacing view" do
      forwards(fn ->
        Familiar.create_view(:chickens, version: 2)
      end)

      backwards(fn ->
        Familiar.replace_view(:chickens, version: 2, revert: 1)
      end)

      view = get_view_def("chickens")
      assert view =~ "WHERE animals.species::text = 'chicken'::text;"
    end
  end

  describe "drop_view" do
    test "can drop view" do
      forwards(fn ->
        Familiar.create_view(:chickens, version: 1)
        Familiar.drop_view(:chickens)
      end)

      refute view_exists?("chickens")
    end

    test "can revert dropping a view" do
      backwards(fn ->
        Familiar.drop_view(:chickens, revert: 1)
      end)

      view = get_view_def("chickens")
      assert view =~ "WHERE animals.species::text = 'chicken'::text;"
    end
  end

  defp forwards(code) do
    run(code, :forward)
  end

  defp backwards(code) do
    run(code, :backward)
  end

  defp run(code, direction) do
    log = %{level: false, sql: false}
    {:ok, runner} =
      Runner.start_link(
        {self(), Repo, Repo.config(), __MODULE__, direction, :up, log}
      )

    Runner.metadata(runner, %{})
    code.()
    flush()
    Runner.stop()
  end

  defp get_view_def(view_name) do
    %{rows: [[definition]]} = query!("SELECT pg_get_viewdef('#{view_name}'::regclass, true)")
    definition
  end

  defp view_exists?(view_name) do
    %{rows: [[result]]} = query!("SELECT to_regclass('public.#{view_name}')")
    result
  end

  defp query!(sql) do
    Ecto.Adapters.SQL.query!(Repo, sql, [], log: false)
  end
end
