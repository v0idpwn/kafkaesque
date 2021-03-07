defmodule Kafkaesque.Test.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :kafkaesque,
    adapter: Ecto.Adapters.Postgres
end
