defmodule Familiar do
  defmacro __using__(_opts) do
    quote do
      import Familiar
    end
  end

  def create_view(view_name, opts) do
    view_name = normalise_name(view_name)
    version = Keyword.fetch!(opts, :version)
    materialized = Keyword.get(opts, :materialized, false)

    new_sql = read_file(:views, view_name, version)

    execute(
      create_view_sql(view_name, new_sql, materialized),
      drop_view_sql(view_name, materialized)
    )
  end

  def update_view(view_name, opts) do
    view_name = normalise_name(view_name)

    version = Keyword.fetch!(opts, :version)
    materialized = Keyword.get(opts, :materialized, false)
    revert = Keyword.get(opts, :revert)

    new_sql = read_file(:views, view_name, version)

    if revert do
      old_sql = read_file(:views, view_name, revert)

      execute(
        drop_and_create_view(view_name, new_sql, materialized),
        drop_and_create_view(view_name, old_sql, materialized)
      )
    else
      execute(drop_and_create_view(view_name, new_sql, materialized))
    end
  end

  def replace_view(view_name, opts) do
    view_name = normalise_name(view_name)

    version = Keyword.fetch!(opts, :version)
    revert = Keyword.get(opts, :revert)

    new_sql = read_file(:views, view_name, version)

    if revert do
      old_sql = read_file(:views, view_name, revert)

      execute(replace_view_sql(view_name, new_sql), replace_view_sql(view_name, old_sql))
    else
      execute(replace_view_sql(view_name, new_sql))
    end
  end

  def drop_view(view_name, opts \\ []) do
    revert = Keyword.get(opts, :revert)
    view_name = normalise_name(view_name)
    materialized = Keyword.get(opts, :materialized, false)

    if revert do
      sql = read_file(:views, view_name, revert)

      execute(
        drop_view_sql(view_name, materialized),
        create_view_sql(view_name, sql, materialized)
      )
    else
      execute(drop_view_sql(view_name, materialized))
    end
  end

  def create_function(function_name, opts) do
    function_name = normalise_name(function_name)

    version = Keyword.fetch!(opts, :version)
    new_sql = read_file(:functions, function_name, version)

    execute(
      create_function_sql(function_name, new_sql),
      drop_function_sql(function_name)
    )
  end

  def update_function(function_name, opts) do
    function_name = normalise_name(function_name)

    version = Keyword.fetch!(opts, :version)
    revert = Keyword.get(opts, :revert)

    new_sql = read_file(:functions, function_name, version)

    if revert do
      old_sql = read_file(:functions, function_name, revert)

      execute(
        drop_and_create_function(function_name, new_sql),
        drop_and_create_function(function_name, old_sql)
      )
    else
      execute(drop_and_create_function(function_name, new_sql))
    end
  end

  def replace_function(function_name, opts) do
    function_name = normalise_name(function_name)

    version = Keyword.fetch!(opts, :version)
    revert = Keyword.get(opts, :revert)

    new_sql = read_file(:functions, function_name, version)

    if revert do
      old_sql = read_file(:functions, function_name, revert)

      execute(
        replace_function_sql(function_name, new_sql),
        replace_function_sql(function_name, old_sql)
      )
    else
      execute(replace_function_sql(function_name, new_sql))
    end
  end

  defp normalise_name(view_name) do
    "#{view_name}"
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

  defp create_view_sql(view_name, sql, materialized) do
    m = if materialized, do: "MATERIALIZED", else: ""
    "CREATE #{m} VIEW #{view_name} AS #{sql};"
  end

  defp replace_view_sql(view_name, sql) do
    "CREATE OR REPLACE VIEW #{view_name} AS #{sql};"
  end

  defp drop_view_sql(view_name, materialized) do
    m = if materialized, do: "MATERIALIZED", else: ""
    "DROP #{m} VIEW #{view_name};"
  end

  defp drop_and_create_view(view_name, sql, materialized) do
    [drop_view_sql(view_name, materialized), create_view_sql(view_name, sql, materialized)]
  end

  defp create_function_sql(function_name, sql) do
    "CREATE FUNCTION #{function_name} #{sql};"
  end

  defp replace_function_sql(function_name, sql) do
    "CREATE OR REPLACE FUNCTION #{function_name} #{sql};"
  end

  defp drop_function_sql(function_name) do
    "DROP FUNCTION #{function_name}"
  end

  defp drop_and_create_function(function_name, sql) do
    [drop_function_sql(function_name), create_function_sql(function_name, sql)]
  end

  defp read_file(type, view_name, version) do
    File.read!(make_dir(type) <> "/#{view_name}_v#{version}.sql")
  end

  defp make_dir(type) do
    otp_app = Ecto.Migration.repo().config()[:otp_app]
    Application.app_dir(otp_app, "priv/repo/#{type}/")
  end
end
