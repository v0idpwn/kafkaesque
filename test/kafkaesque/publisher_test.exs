defmodule Kafkaesque.PublisherTest do
  use Kafkaesque.Case, async: true

  alias Kafkaesque.Publisher

  describe "client/1" do
    @tag :integration
    test "creates a brod client" do
      {:ok, _id} = Publisher.client(address: :localhost, port: 9092, client_id: :test_client_1)
    end

    test "raises if missing client_id" do
      assert_raise KeyError, fn ->
        Publisher.client(address: :localhost, port: 9092)
      end
    end

    test "raises if missing address" do
      assert_raise KeyError, fn ->
        Publisher.client(client_id: :test_client_2, port: 9092)
      end
    end

    test "raises if missing port" do
      assert_raise KeyError, fn ->
        Publisher.client(address: :localhost, client: :test_client_3)
      end
    end
  end

  describe "publish/2" do
    @tag :integration
    test "publishes on kafka" do
      {:ok, client} = Publisher.client(address: :localhost, port: 9092, client_id: :test_client_4)
      assert {:ok, _offset} = Publisher.publish(client, %{topic: "sample_topic", body: %{}})
    end
  end
end
