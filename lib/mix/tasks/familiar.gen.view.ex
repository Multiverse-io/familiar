defmodule Mix.Tasks.Familiar.Gen.View do
  use Mix.Task
  import Mix.Generator
  import Mix.Ecto
  import Mix.EctoSQL

  @switches [
    version: :integer
  ]

  @impl true
  def run(args) do
    no_umbrella!("familiar.gen.view")
    repos = parse_repo(args)

    case OptionParser.parse!(args, strict: @switches) do
      {opts, [name]} ->
        repo = hd(repos)
        ensure_repo(repo, args)
        dir = Path.join(source_repo_priv(repo), "views")

        {version, contents} = get_version(name, dir, opts)
        filename = "#{name}_v#{version}.sql"

        path = "#{dir}/#{filename}"
        create_file(path, contents)
    end
  end

  defp get_version(name, dir, opts) do
    if version = Keyword.get(opts, :version) do
      {version, ""}
    else
      possible_views = Path.wildcard("#{dir}/#{name}_v*")

      versions =
        Enum.flat_map(possible_views, fn filename ->
          case Regex.run(~r|#{name}_v(\d+).sql$|, filename) do
            [_, v] -> [{filename, String.to_integer(v)}]
            _ -> []
          end
        end)

      if versions == [] do
        {1, ""}
      else
        {filename, version} = Enum.max_by(versions, &elem(&1, 1))
        old_contents = File.read!(filename)
        {version + 1, old_contents}
      end
    end
  end
end
