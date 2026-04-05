defmodule PAEx.Repo do
  use AshPostgres.Repo, otp_app: :pa_ex

  def installed_extensions do
    ["uuid-ossp", "citext"]
  end

  def min_pg_version do
    %Version{major: 14, minor: 0, patch: 0}
  end
end
