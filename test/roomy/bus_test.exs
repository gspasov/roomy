defmodule Roomy.BusTest do
  use Roomy.DataCase, async: true

  alias Roomy.Bus
  alias Roomy.Utils
  alias Roomy.TestUtils
  alias Roomy.Models.Message

  require Bus.Topic

  test "subscribers to particular topic receive message published to that topic" do
    room_id = "room_101"

    subscriber =
      room_id
      |> Bus.Topic.room()
      |> TestUtils.subscribe_to_topic()

    sent_at = DateTime.utc_now()
    # Give some time for the other process to subscribe to the topic
    # before sending the message
    Utils.execute_after(
      200,
      fn ->
        Bus.Event.send_message(%Message{
          id: 1,
          sender_id: 2,
          content: "hello world",
          room_id: room_id,
          sent_at: sent_at
        })
      end
    )

    message_to_receive = %Message{
      id: 1,
      content: "hello world",
      room_id: room_id,
      sender_id: 2,
      sent_at: sent_at
    }

    assert Task.await(subscriber) == {Bus, message_to_receive}
  end

  test "subscribers should not receive message sent to a different topic" do
    room_id = "room_101"

    task =
      Task.async(fn ->
        Bus.subscribe(Bus.Topic.user("123"))

        receive do
          {Bus, %Message{content: content}} -> content
        end
      end)

    # Give some time for the other process to subscribe to the topic
    # before sending the message

    Utils.execute_after(
      200,
      fn ->
        Bus.Event.send_message(%Message{
          id: 1,
          sender_id: 2,
          content: "hello world",
          room_id: room_id,
          sent_at: DateTime.utc_now()
        })

        assert catch_exit(Task.await(task, 1_000))
      end
    )
  end
end
