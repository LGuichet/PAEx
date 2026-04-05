defmodule PAExWeb.ErrorHTML do
  @moduledoc false
  use PAExWeb, :html

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
