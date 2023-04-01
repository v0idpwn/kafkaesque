defmodule Kafkaesque.Message.PartitionKey do
  @doc """
  Simple jsonb type that supports only strings and integers
  """

  use Ecto.Type

  def type, do: :jsonb

  def cast(key) when is_integer(key) or is_binary(key) do
    {:ok, key}
  end

  def cast(_key) do
    :error
  end

  def load(key) do
    key
    |> Jason.decode()
    |> sanitize_error()
  end

  def dump(key) do
    key
    |> Jason.encode()
    |> sanitize_error()
  end

  defp sanitize_error({:error, _}), do: :error
  defp sanitize_error(ok), do: ok
end
