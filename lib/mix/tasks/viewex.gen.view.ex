defmodule Mix.Tasks.Viewex.Gen.View do
  use Mix.Task
  import Mix.Generator

  @switches [
    version: :integer
  ]

  @impl true
  def run(args) do
    case OptionParser.parse!(args, strict: @switches) do
      {opts, [name]} ->
        version = Keyword.get(opts, :version, 1)
        filename = "#{name}_v#{version}.sql"

        path = "#{dir()}/#{filename}"
        create_file path, ""
    end
  end

  defp dir do
    Application.app_dir(:viewex, "priv/repo/views/")
  end
end
