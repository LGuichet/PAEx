defmodule PAExWeb.FallbackController do
  @moduledoc """
  Translates Ash errors and Ecto changesets into HTTP error responses.
  """
  use PAExWeb, :controller

  def call(conn, {:error, %Ash.Error.Query.NotFound{}}) do
    conn
    |> put_status(:not_found)
    |> json(%{errors: [%{status: "404", title: "Not Found"}]})
  end

  def call(conn, {:error, %Ash.Error.Invalid{} = error}) do
    errors =
      error.errors
      |> List.wrap()
      |> Enum.map(&format_error/1)

    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: errors})
  end

  def call(conn, {:error, %Ash.Error.Forbidden{}}) do
    conn
    |> put_status(:forbidden)
    |> json(%{errors: [%{status: "403", title: "Forbidden"}]})
  end

  def call(conn, {:error, reason}) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{errors: [%{status: "500", title: "Internal Server Error", detail: inspect(reason)}]})
  end

  defp format_error(%{message: message, field: field}) when not is_nil(field) do
    %{status: "422", title: "Validation Error", source: %{pointer: "/data/attributes/#{field}"}, detail: message}
  end

  defp format_error(%{message: message}) do
    %{status: "422", title: "Validation Error", detail: message}
  end

  defp format_error(error) do
    %{status: "422", title: "Validation Error", detail: inspect(error)}
  end
end
