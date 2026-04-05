defmodule PAExWeb.ErrorJSON do
  @moduledoc false

  def render("404.json", _assigns) do
    %{errors: [%{status: "404", title: "Not Found"}]}
  end

  def render("500.json", _assigns) do
    %{errors: [%{status: "500", title: "Internal Server Error"}]}
  end
end
