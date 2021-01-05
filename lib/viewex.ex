defmodule Viewex do
  defmacro __using__(_opts) do
    quote do
      import Viewex
    end
  end

  def create_view(view_name, opts) do
    view_name = normalise_view_name(view_name)

    version = Keyword.fetch!(opts, :version)

    new_sql = read_file(view_name, version)

    Ecto.Migration.execute(create_sql(view_name, new_sql), drop_sql(view_name))
  end

  def update_view(view_name, opts) do
    view_name = normalise_view_name(view_name)

    to = Keyword.fetch!(opts, :to)
    revert = Keyword.get(opts, :revert)

    new_sql = read_file(view_name, to)

    if revert do
      old_sql = read_file(view_name, revert)

      Ecto.Migration.execute(
        fn -> drop_and_create(view_name, new_sql) end,
        fn -> drop_and_create(view_name, old_sql) end
      )
    else
      Ecto.Migration.execute(fn -> drop_and_create(view_name, new_sql) end)
    end
  end

  def replace_view(view_name, opts) do
    view_name = normalise_view_name(view_name)

    to = Keyword.fetch!(opts, :with)
    revert = Keyword.get(opts, :revert)

    new_sql = read_file(view_name, to)

    if revert do
      old_sql = read_file(view_name, revert)

      Ecto.Migration.execute(
        replace_sql(view_name, new_sql),
        replace_sql(view_name, old_sql)
      )
    else
      Ecto.Migration.execute(fn -> replace_sql(view_name, new_sql) end)
    end
  end

  defp normalise_view_name(view_name) do
    "#{view_name}"
  end

  defp drop_and_create(view_name, sql) do
    Ecto.Migration.repo().query!(drop_sql(view_name))
    Ecto.Migration.repo().query!(create_sql(view_name, sql))
  end

  defp create_sql(view_name, sql) do
    "CREATE VIEW #{view_name} AS #{sql};"
  end

  defp replace_sql(view_name, sql) do
    "CREATE OR REPLACE VIEW #{view_name} AS #{sql};"
  end

  defp drop_sql(view_name) do
    "DROP VIEW #{view_name};"
  end

  defp read_file(view_name, version) do
    File.read!(view_dir() <> "/#{view_name}_v#{version}.sql")
  end

  defp view_dir do
    Application.app_dir(:viewex, "priv/repo/views/")
  end
end
