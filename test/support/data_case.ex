defmodule Familiar.DataCase do
  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Familiar.DataCase
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Familiar.Repo)
    unless tags[:async] do
      Sandbox.mode(Familiar.Repo, {:shared, self()})
    end

    :ok
  end
end
