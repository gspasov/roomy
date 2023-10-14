defmodule Roomy.MessageTest do
  use Roomy.RoomCase, async: true

  alias Roomy.Bus
  alias Roomy.Account
  alias Roomy.Request
  alias Roomy.Utils
  alias Roomy.Models.Message
  alias Roomy.Models.UserMessage
  alias Roomy.Constants.MessageType

  require Bus.Topic
  require MessageType

  test "Sending message by default is seen false", %{user1: user1, user2: user2, room: room} do
    sent_at = DateTime.utc_now()

    {:ok, %Message{id: message_id}} =
      Account.send_message(%Request.SendMessage{
        content: "hello",
        room_id: room.id,
        sender_id: user1.id,
        sent_at: sent_at
      })

    {:ok, %UserMessage{seen: seen}} =
      UserMessage.get_by(user_id: user2.id, message_id: message_id)

    assert seen == false
  end

  test "all subscribers to a room receive a send message", %{user1: user1, room: room} do
    subscribers =
      Enum.map(1..5, fn _ ->
        room.id
        |> Bus.Topic.room()
        |> subscribe_to_topic()
      end)

    sent_at = DateTime.utc_now()

    # Give some time for the other process to subscribe to the topic
    # before sending the message
    {:ok, %Message{id: message_id, content: content}} =
      Utils.execute_after(
        200,
        fn ->
          Account.send_message(%Request.SendMessage{
            content: "hello",
            room_id: room.id,
            sender_id: user1.id,
            sent_at: sent_at
          })
        end
      )

    message_to_receive =
      strip_unnecessary_fields(%Message{
        id: message_id,
        type: MessageType.normal(),
        content: content,
        room_id: room.id,
        sender_id: user1.id,
        sent_at: sent_at,
        deleted: false,
        edited: false
      })

    Enum.each(subscribers, fn sub ->
      assert {Bus, message} = Task.await(sub)
      assert strip_unnecessary_fields(message) == message_to_receive
    end)
  end

  test "fetch unread messages", %{user1: user1, user2: user2, room: room} do
    sent_at_1 = DateTime.utc_now()

    {:ok, %Message{id: read_message_id}} =
      Account.send_message(%Request.SendMessage{
        content: "hello",
        room_id: room.id,
        sender_id: user1.id,
        sent_at: sent_at_1
      })

    sent_at_2 = DateTime.utc_now()

    {:ok, %Message{id: unread_message_id}} =
      Account.send_message(%Request.SendMessage{
        content: "hello ??",
        room_id: room.id,
        sender_id: user1.id,
        sent_at: sent_at_2
      })

    # Read the first message
    Account.read_message(%Request.ReadMessage{message_id: read_message_id, reader_id: user2.id})

    # The second message should be still unread
    [unread_message] =
      Account.fetch_unread_messages(%Request.FetchUnreadMessages{
        reader_id: user2.id,
        room_id: room.id
      })

    assert strip_unnecessary_fields(unread_message) ==
             %{
               id: unread_message_id,
               content: "hello ??",
               room_id: room.id,
               sender_id: user1.id,
               edited: false,
               edited_at: nil,
               deleted: false,
               sent_at: sent_at_2,
               type: MessageType.normal(),
               seen: unread_message.seen
             }
  end

  test "can edit message that is not read", %{user1: user1, room: room} do
    sent_at = DateTime.utc_now()

    {:ok, %Message{id: message_id}} =
      Account.send_message(%Request.SendMessage{
        content: "hello",
        room_id: room.id,
        sender_id: user1.id,
        sent_at: sent_at
      })

    edited_at = DateTime.utc_now()

    :ok =
      Account.edit_message(%Request.EditMessage{
        message_id: message_id,
        content: "well hello there",
        edited_at: edited_at
      })

    {:ok, %Message{} = message} = Message.get(message_id)

    assert message.content == "well hello there"
  end

  test "cannot edit message that is read", %{user1: user1, user2: user2, room: room} do
    sent_at = DateTime.utc_now()

    {:ok, %Message{id: message_id}} =
      Account.send_message(%Request.SendMessage{
        content: "hello",
        room_id: room.id,
        sender_id: user1.id,
        sent_at: sent_at
      })

    Account.read_message(%Request.ReadMessage{message_id: message_id, reader_id: user2.id})

    edited_at = DateTime.utc_now()

    {:error, :message_is_read} =
      Account.edit_message(%Request.EditMessage{
        message_id: message_id,
        content: "well hello there",
        edited_at: edited_at
      })

    {:ok, %Message{} = message} = Message.get(message_id)

    assert message.content == "hello"
  end

  test "Deleting a message", %{user1: user1, room: room} do
    sent_at = DateTime.utc_now()

    {:ok, %Message{id: message_id}} =
      Account.send_message(%Request.SendMessage{
        content: "hello",
        room_id: room.id,
        sender_id: user1.id,
        sent_at: sent_at
      })

    {:ok, %Message{}} = Account.delete_message(message_id)
    {:ok, %Message{} = message} = Message.get(message_id)

    assert strip_unnecessary_fields(message) == %{
             id: message_id,
             content: "[system] Deleted message",
             room_id: room.id,
             sender_id: user1.id,
             edited: false,
             edited_at: nil,
             deleted: true,
             sent_at: sent_at,
             type: MessageType.normal(),
             seen: message.seen
           }
  end
end
