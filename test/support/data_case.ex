defmodule PAEx.DataCase do
  @moduledoc """
  Base test case for tests that need a database connection.

  Sets up the SQL sandbox for each test and provides helpers for building
  Ash changesets/queries in the test context.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      alias PAEx.Repo

      import Ecto
      import Ecto.Query
      import PAEx.DataCase
    end
  end

  setup tags do
    PAEx.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(PAEx.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
