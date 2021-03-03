defmodule FamiliarTest do
  use Familiar.DataCase
  use Ecto.Migration
  import Ecto.Query
  alias Ecto.Migration.Runner
  alias Familiar.Repo

  setup do
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
      refute materialized_view_exists?("chickens")
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

    test "can create materialized view" do
      forwards(fn ->
        Familiar.create_view(:chickens, version: 1, materialized: true)
      end)

      assert materialized_view_exists?("chickens")
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
      refute materialized_view_exists?("chickens")
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

    test "can update materialized view" do
      forwards(fn ->
        Familiar.create_view(:chickens, version: 1, materialized: true)
        Familiar.update_view(:chickens, version: 2, materialized: true)
      end)

      view = get_view_def("chickens")
      assert view =~ "WHERE animals.species::text = 'chicken'::text AND animals.alive = true;"
      assert materialized_view_exists?("chickens")
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

    test "can drop materialized view" do
      forwards(fn ->
        Familiar.create_view(:chickens, version: 1, materialized: true)
        Familiar.drop_view(:chickens, materialized: true)
      end)

      refute view_exists?("chickens")
    end

    test "reverting dropping a materialized view creates a materialized view" do
      backwards(fn ->
        Familiar.drop_view(:chickens, revert: 1, materialized: true)
      end)

      assert materialized_view_exists?("chickens")
    end
  end

  describe "create_function" do
    test "can create function" do
      forwards(fn ->
        Familiar.create_function(:mix, version: 1)
      end)

      get_function_def("mix") =~ "select $1 + $2"

      assert function_exists?("mix")
    end

    test "can create function v2" do
      forwards(fn ->
        Familiar.create_function(:mix, version: 2)
      end)

      get_function_def("mix") =~ "select $1 * $2"

      assert function_exists?("mix")
    end

    test "can revert creating function" do
      forwards(fn ->
        Familiar.create_function(:mix, version: 1)
      end)

      backwards(fn ->
        Familiar.create_function(:mix, version: 1)
      end)

      refute function_exists?("mix")
    end
  end

  test "update_function"
  test "replace_function"
  test "drop_function"

  defp forwards(code) do
    run(code, :forward)
  end

  defp backwards(code) do
    run(code, :backward)
  end

  defp run(code, direction) do
    log = %{level: false, sql: false}

    {:ok, runner} =
      Runner.start_link({self(), Repo, Repo.config(), __MODULE__, direction, :up, log})

    Runner.metadata(runner, %{})
    code.()
    flush()
    Runner.stop()
  end

  defp get_view_def(view_name) do
    %{rows: [[definition]]} = query!("SELECT pg_get_viewdef('#{view_name}'::regclass, true)")
    definition
  end

  defp get_function_def(function_name) do
    %{rows: [[definition]]} =
      query!("SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = '#{function_name}'")

    definition
  end

  defp view_exists?(view_name) do
    Repo.exists?(
      from(v in "pg_views", where: v.viewname == ^view_name and v.schemaname == "public")
    )
  end

  defp materialized_view_exists?(view_name) do
    Repo.exists?(
      from(mv in "pg_matviews", where: mv.matviewname == ^view_name and mv.schemaname == "public")
    )
  end

  defp function_exists?(function_name) do
    Repo.exists?(from(p in "pg_proc", where: p.proname == ^function_name))
  end

  defp query!(sql) do
    Ecto.Adapters.SQL.query!(Repo, sql, [], log: false)
  end
end
