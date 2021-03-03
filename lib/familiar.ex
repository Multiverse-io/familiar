defmodule Familiar do
  defmacro __using__(_opts) do
    quote do
      import Familiar
    end
  end

  def create_view(view_name, opts) do
    view_name = normalise_view_name(view_name)
    version = Keyword.fetch!(opts, :version)
    materialized = Keyword.get(opts, :materialized, false)

    new_sql = read_file(view_name, version)
    execute(create_sql(view_name, new_sql, materialized), drop_sql(view_name, materialized))
  end

  def update_view(view_name, opts) do
    view_name = normalise_view_name(view_name)

    version = Keyword.fetch!(opts, :version)
    materialized = Keyword.get(opts, :materialized, false)
    revert = Keyword.get(opts, :revert)

    new_sql = read_file(view_name, version)

    if revert do
      old_sql = read_file(view_name, revert)

      execute(
        drop_and_create(view_name, new_sql, materialized),
        drop_and_create(view_name, old_sql, materialized)
      )
    else
      execute(drop_and_create(view_name, new_sql, materialized))
    end
  end

  def replace_view(view_name, opts) do
    view_name = normalise_view_name(view_name)

    version = Keyword.fetch!(opts, :version)
    revert = Keyword.get(opts, :revert)

    new_sql = read_file(view_name, version)

    if revert do
      old_sql = read_file(view_name, revert)

      execute(replace_sql(view_name, new_sql), replace_sql(view_name, old_sql))
    else
      execute(replace_sql(view_name, new_sql))
    end
  end

  def drop_view(view_name, opts \\ []) do
    revert = Keyword.get(opts, :revert)
    view_name = normalise_view_name(view_name)
    materialized = Keyword.get(opts, :materialized, false)

    if revert do
      sql = read_file(view_name, revert)
      execute(drop_sql(view_name, materialized), create_sql(view_name, sql, materialized))
    else
      execute(drop_sql(view_name, materialized))
    end
  end

  defp normalise_view_name(view_name) do
    "#{view_name}"
  end

  defp drop_and_create(view_name, sql, materialized) do
    [drop_sql(view_name, materialized), create_sql(view_name, sql, materialized)]
  end

  defp execute(sql) do
    Ecto.Migration.execute(wrap(sql))
  end

  defp execute(up, down) do
    Ecto.Migration.execute(wrap(up), wrap(down))
  end

  defp wrap(statements) when is_list(statements) do
    fn ->
      for sql <- statements do
        Ecto.Migration.repo().query!(sql)
      end
    end
  end

  defp wrap(sql) do
    fn -> Ecto.Migration.repo().query!(sql) end
  end

  defp create_sql(view_name, sql, materialized) do
    if materialized do
      "CREATE MATERIALIZED VIEW #{view_name} AS #{sql};"
    else
      "CREATE VIEW #{view_name} AS #{sql};"
    end
  end

  defp replace_sql(view_name, sql) do
    "CREATE OR REPLACE VIEW #{view_name} AS #{sql};"
  end

  defp drop_sql(view_name, materialized) do
    if materialized do
      "DROP MATERIALIZED VIEW #{view_name};"
    else
      "DROP VIEW #{view_name};"
    end
  end

  defp read_file(view_name, version) do
    File.read!(view_dir() <> "/#{view_name}_v#{version}.sql")
  end

  defp view_dir do
    otp_app = Ecto.Migration.repo().config()[:otp_app]
    Application.app_dir(otp_app, "priv/repo/views/")
  end
end
