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
        version = get_version(name, opts)

        filename = "#{name}_v#{version}.sql"

        path = "#{dir()}/#{filename}"
        create_file path, ""
    end
  end

  defp get_version(name, opts) do
    if version = Keyword.get(opts, :version) do
      version
    else
      possible_views = Path.wildcard("#{dir()}/#{name}_v*")

      views = Enum.flat_map(possible_views, fn filename ->
        String.match?(filename, ~r|^#{name}_v\d+\.sql$|)
      end)
    end
  end

  defp dir do
    Application.app_dir(:viewex, "priv/repo/views/")
  end
end
