defmodule PAEx.ConnCase do
  @moduledoc """
  Base test case for controller / integration tests.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use PAExWeb, :verified_routes

      alias PAEx.Repo
      import Plug.Conn
      import Phoenix.ConnTest
      import PAEx.ConnCase

      @endpoint PAExWeb.Endpoint
    end
  end

  setup tags do
    PAEx.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
