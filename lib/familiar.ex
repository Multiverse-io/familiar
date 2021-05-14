defmodule Familiar do

  @moduledoc """
  Helper functions for creating database views and functions - your database's
  familiars.

  View and function definitions are stored as SQL files in `priv/repo/views` and
  `priv/repo/functions` respectively.

  Each definition file has the following file name format:

      NAME_vNUMBER.sql

  The NAME will be the name of the created database object and will be what is
  used to refer to it in the functions defined in this module. The NUMBER is the
  version number and should be incremented whenever a view or function is
  revised. Old versions should be kept and shouldn't be modified once deployed.

  A view definition file can be generated using the following mix task:

      $ mix familiar.gen.view my_view

  ## Example

  Given the following view definition in `priv/repo/views/active_users_v1.sql`:

      SELECT * FROM users
      WHERE users.active = TRUE;

  The view can be created like so:

      defmodule MyRepo.Migrations.CreateActiveUsers do
        use Ecto.Migration
        use Familiar

        def change do
          create_view :active_users
        end
      end

  ### Updating the view

  If we want to update the `active_users` view created above, we can first generate a new version of the view by running:

      $ mix familiar.gen.view active_users

  And then editing the generated `active_users_v2.sql` as needed. Then the view can be updated in a migration:

      defmodule MyRepo.Migrations.UpdateActiveUsers do
        use Ecto.Migration
        use Familiar

        def change do
          update_view :active_users, revert: 1
        end
      end

  The `:revert` option is optional however if it is omitted the migration will not be reversible.
  """

  defmacro __using__(_opts) do
    quote do
      import Familiar
    end
  end

  @doc """
  Creates a new database view from a view definition file.

  ## Options:
    * `:version` - the version of the view to create
    * `:materialized` - whether the view is materialized or not. Defaults to `false`.
  """
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

  @doc """
  Updates a database view from a view definition file.

  This function will drop the existing view and then create the new version of
  the view so dependant views, functions, triggers etc will need to be dropped
  first.

  ## Options:
    * `:version` - the version of the updated view
    * `:materialized` - whether the view is materialized or not. Defaults to `false`.
    * `:revert` - the version to revert to if the migration is rolled back
  """
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

  @doc """
  Replaces a database view from a view definition file.

  This function will use `CREATE OR REPLACE VIEW` so can only be used if the new
  version has the same columns as the old version.

  ## Options:
    * `:version` - the version of the updated view
    * `:materialized` - whether the view is materialized or not. Defaults to `false`.
    * `:revert` - the version to revert to if the migration is rolled back
  """
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

  @doc """
  Drops a database view.

  ## Options:
    * `:materialized` - whether the view is materialized or not. Defaults to `false`.
    * `:revert` - the version to create if the migration is rolled back
  """
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

  @doc """
  Creates a new database function from a function definition file.

  ## Options:
    * `:version` - the version of the function to create
  """
  def create_function(function_name, opts) do
    function_name = normalise_name(function_name)

    version = Keyword.fetch!(opts, :version)
    new_sql = read_file(:functions, function_name, version)

    execute(
      create_function_sql(function_name, new_sql),
      drop_function_sql(function_name)
    )
  end

  @doc """
  Updates a new database function from a function definition file.

  This function will drop the existing function before creating a new function
  so dependant views, functions, triggers etc will need to be dropped first.

  ## Options:
    * `:version` - the version of the updated function
    * `:revert` - the version to revert to if the migration is rolled back
  """
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

  @doc """
  Replaces a new database function from a function definition file.

  This function will use `CREATE OR REPLACE FUNCTION` so can only be used if the new
  version has the same arguments and return type as the old version.

  ## Options:
    * `:version` - the version of the updated function
    * `:revert` - the version to revert to if the migration is rolled back
  """
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

  @doc """
  Drops a database function.

  ## Options:
    * `:revert` - the version to create if the migration is rolled back
  """
  def drop_function(function_name, opts \\ []) do
    function_name = normalise_name(function_name)
    revert = Keyword.get(opts, :revert)

    if revert do
      old_sql = read_file(:functions, function_name, revert)

      execute(
        drop_function_sql(function_name),
        create_function_sql(function_name, old_sql)
      )
    else
      execute(drop_function_sql(function_name))
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
