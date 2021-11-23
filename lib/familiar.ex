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

  The new version number can be specified explicitly if desired:

      $ mix familiar.gen.view my_view --version 3

  ### Non default schema

  Definition to be created in the non default schema can be placed in
  a subdirectory with the name of the schema. For example
  `priv/repo/views/bi/analytics_v1.sql` will create a the `analytics`
  view in the `bi` schema.

  The `:schema` option then needs to be added to each function call.
  The `--schema` option can be also be passed to `familiar.gen.view`.
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
    * `:schema` - the schema to create the view in. Creates in default schema if not specified
  """
  def create_view(view_name, opts) do
    view_name = normalise_name(view_name)
    version = Keyword.fetch!(opts, :version)
    materialized = Keyword.get(opts, :materialized, false)
    schema = Keyword.get(opts, :schema)

    new_sql = read_file(:views, view_name, version, schema)

    execute(
      create_view_sql(view_name, new_sql, materialized, schema),
      drop_view_sql(view_name, materialized, schema)
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
    * `:schema` - the schema the view lives in. Uses default schema if not specified
  """
  def update_view(view_name, opts) do
    view_name = normalise_name(view_name)

    version = Keyword.fetch!(opts, :version)
    materialized = Keyword.get(opts, :materialized, false)
    schema = Keyword.get(opts, :schema)
    revert = Keyword.get(opts, :revert)

    new_sql = read_file(:views, view_name, version, schema)

    if revert do
      old_sql = read_file(:views, view_name, revert, schema)

      execute(
        drop_and_create_view(view_name, new_sql, materialized, schema),
        drop_and_create_view(view_name, old_sql, materialized, schema)
      )
    else
      execute(drop_and_create_view(view_name, new_sql, materialized, schema))
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
    * `:schema` - the schema the view lives in. Uses default schema if not specified
  """
  def replace_view(view_name, opts) do
    view_name = normalise_name(view_name)

    version = Keyword.fetch!(opts, :version)
    schema = Keyword.get(opts, :schema)
    revert = Keyword.get(opts, :revert)

    new_sql = read_file(:views, view_name, version, schema)

    if revert do
      old_sql = read_file(:views, view_name, revert, schema)

      execute(
        replace_view_sql(view_name, new_sql, schema),
        replace_view_sql(view_name, old_sql, schema)
      )
    else
      execute(replace_view_sql(view_name, new_sql, schema))
    end
  end

  @doc """
  Drops a database view.

  ## Options:
    * `:materialized` - whether the view is materialized or not. Defaults to `false`.
    * `:revert` - the version to create if the migration is rolled back
    * `:schema` - the schema the view lives in. Uses default schema if not specified
  """
  def drop_view(view_name, opts \\ []) do
    revert = Keyword.get(opts, :revert)
    view_name = normalise_name(view_name)
    schema = Keyword.get(opts, :schema)
    materialized = Keyword.get(opts, :materialized, false)

    if revert do
      sql = read_file(:views, view_name, revert, schema)

      execute(
        drop_view_sql(view_name, materialized, schema),
        create_view_sql(view_name, sql, materialized, schema)
      )
    else
      execute(drop_view_sql(view_name, materialized, schema))
    end
  end

  @doc """
  Creates a new database function from a function definition file.

  ## Options:
    * `:version` - the version of the function to create
    * `:schema` - the schema to create the function in. Uses default schema if not specified
  """
  def create_function(function_name, opts) do
    function_name = normalise_name(function_name)

    version = Keyword.fetch!(opts, :version)
    schema = Keyword.get(opts, :schema)
    new_sql = read_file(:functions, function_name, version, schema)

    execute(
      create_function_sql(function_name, new_sql, schema),
      drop_function_sql(function_name, schema)
    )
  end

  @doc """
  Updates a new database function from a function definition file.

  This function will drop the existing function before creating a new function
  so dependant views, functions, triggers etc will need to be dropped first.

  ## Options:
    * `:version` - the version of the updated function
    * `:revert` - the version to revert to if the migration is rolled back
    * `:schema` - the schema the function lives in. Uses default schema if not specified
  """
  def update_function(function_name, opts) do
    function_name = normalise_name(function_name)

    version = Keyword.fetch!(opts, :version)
    schema = Keyword.get(opts, :schema)
    revert = Keyword.get(opts, :revert)

    new_sql = read_file(:functions, function_name, version, schema)

    if revert do
      old_sql = read_file(:functions, function_name, revert, schema)

      execute(
        drop_and_create_function(function_name, new_sql, schema),
        drop_and_create_function(function_name, old_sql, schema)
      )
    else
      execute(drop_and_create_function(function_name, new_sql, schema))
    end
  end

  @doc """
  Replaces a new database function from a function definition file.

  This function will use `CREATE OR REPLACE FUNCTION` so can only be used if the new
  version has the same arguments and return type as the old version.

  ## Options:
    * `:version` - the version of the updated function
    * `:revert` - the version to revert to if the migration is rolled back
    * `:schema` - the schema the function lives in. Uses default schema if not specified
  """
  def replace_function(function_name, opts) do
    function_name = normalise_name(function_name)

    version = Keyword.fetch!(opts, :version)
    schema = Keyword.get(opts, :schema)
    revert = Keyword.get(opts, :revert)

    new_sql = read_file(:functions, function_name, version, schema)

    if revert do
      old_sql = read_file(:functions, function_name, revert, schema)

      execute(
        replace_function_sql(function_name, new_sql, schema),
        replace_function_sql(function_name, old_sql, schema)
      )
    else
      execute(replace_function_sql(function_name, new_sql, schema))
    end
  end

  @doc """
  Drops a database function.

  ## Options:
    * `:revert` - the version to create if the migration is rolled back
    * `:schema` - the schema the function lives in. Uses default schema if not specified
  """
  def drop_function(function_name, opts \\ []) do
    function_name = normalise_name(function_name)
    schema = Keyword.get(opts, :schema)
    revert = Keyword.get(opts, :revert)

    if revert do
      old_sql = read_file(:functions, function_name, revert, schema)

      execute(
        drop_function_sql(function_name, schema),
        create_function_sql(function_name, old_sql, schema)
      )
    else
      execute(drop_function_sql(function_name, schema))
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

  defp create_view_sql(view_name, sql, materialized, schema) do
    m = if materialized, do: "MATERIALIZED", else: ""
    "CREATE #{m} VIEW #{wrap_name(view_name, schema)} AS #{sql};"
  end

  defp replace_view_sql(view_name, sql, schema) do
    "CREATE OR REPLACE VIEW #{wrap_name(view_name, schema)} AS #{sql};"
  end

  defp drop_view_sql(view_name, materialized, schema) do
    m = if materialized, do: "MATERIALIZED", else: ""
    "DROP #{m} VIEW #{wrap_name(view_name, schema)};"
  end

  defp drop_and_create_view(view_name, sql, materialized, schema) do
    [
      drop_view_sql(view_name, materialized, schema),
      create_view_sql(view_name, sql, materialized, schema)
    ]
  end

  defp create_function_sql(function_name, sql, schema) do
    "CREATE FUNCTION #{wrap_name(function_name, schema)} #{sql};"
  end

  defp replace_function_sql(function_name, sql, schema) do
    "CREATE OR REPLACE FUNCTION #{wrap_name(function_name, schema)} #{sql};"
  end

  defp drop_function_sql(function_name, schema) do
    "DROP FUNCTION #{wrap_name(function_name, schema)}"
  end

  defp wrap_name(name, schema) when not is_nil(schema) do
    ~s|"#{schema}"."#{name}"|
  end

  defp wrap_name(name, nil) do
    ~s|"#{name}"|
  end

  defp drop_and_create_function(function_name, sql, schema) do
    [drop_function_sql(function_name, schema), create_function_sql(function_name, sql, schema)]
  end

  defp read_file(type, view_name, version, schema) do
    schema_str = if schema, do: "#{schema}/", else: ""
    File.read!(make_dir(type) <> "/#{schema_str}#{view_name}_v#{version}.sql")
  end

  defp make_dir(type) do
    otp_app = Ecto.Migration.repo().config()[:otp_app]
    Application.app_dir(otp_app, "priv/repo/#{type}/")
  end
end
