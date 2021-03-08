Logger.configure(level: :warn)

ExUnit.start()

Kafkaesque.Test.Repo.start_link()

defmodule Kafkaesque.Case do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias Kafkaesque.Message
  alias Kafkaesque.Test.Repo

  using do
    quote do
      import Kafkaesque.Case

      alias Kafkaesque.Message
      alias Kafkaesque.Test.Repo
    end
  end

  setup tags do
    # We are intentionally avoiding Sandbox mode for testing. Within Sandbox mode everything
    # happens in a transaction, which prevents the use of LISTEN/NOTIFY messages.
    if tags[:integration] do
      Repo.delete_all(Message)

      on_exit(fn ->
        Repo.delete_all(Message)
      end)
    end

    {:ok, %{}}
  end
end
