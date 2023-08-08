defmodule Roomy.BusTest do
  use Roomy.DataCase, async: false

  alias Roomy.Bus

  require Bus.Topic

  test "subscribers to particular topic receive message published to that topic" do
    room_id = "room_101"

    task =
      Task.async(fn ->
        room_id
        |> Bus.Topic.message()
        |> Bus.subscribe()

        receive do
          {Bus, %Bus.Event.Message{content: content}} ->
            content
        end
      end)

    # Give some time for the other process to subscribe to the topic
    # before sending the message

    execute_after(
      200,
      fn ->
        Bus.Event.send_message(%Bus.Event.Message{
          message_id: 1,
          sender_id: 2,
          content: "hello world",
          room_id: room_id,
          sent_at: DateTime.utc_now()
        })

        result = Task.await(task)

        assert result == "hello world"
      end
    )
  end

  test "subscribers should not receive message sent to a different topic" do
    room_id = "room_101"

    task =
      Task.async(fn ->
        Bus.subscribe(Bus.Topic.user("123"))

        receive do
          {Bus, %Bus.Event.Message{content: content}} -> content
        end
      end)

    # Give some time for the other process to subscribe to the topic
    # before sending the message

    execute_after(
      200,
      fn ->
        Bus.Event.send_message(%Bus.Event.Message{
          message_id: 1,
          sender_id: 2,
          content: "hello world",
          room_id: room_id,
          sent_at: DateTime.utc_now()
        })

        assert catch_exit(Task.await(task, 1_000))
      end
    )
  end

  defp execute_after(time, fun) do
    Process.send_after(self(), :do, time)

    receive do
      :do ->
        fun.()
    end
  end
end
