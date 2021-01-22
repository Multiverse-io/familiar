defmodule Mix.Tasks.Familiar.Gen.View do
  use Mix.Task
  import Mix.Generator
  import Mix.Ecto

  @switches [
    version: :integer
  ]

  @impl true
  def run(args) do
    no_umbrella!("familiar.gen.view")
    repos = parse_repo(args)

    case OptionParser.parse!(args, strict: @switches) do
      {opts, [name]} ->
        version = get_version(name, opts)

        filename = "#{name}_v#{version}.sql"
        dir = Path.join(source_repo_priv(hd(repos)), "views")

        path = "#{dir}/#{filename}"
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
end
