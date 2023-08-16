defmodule Roomy.Models.RoomTest do
  use Roomy.DataCase, async: true

  alias Roomy.Request
  alias Roomy.Account
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.Message
  alias Roomy.Models.Invitation
  alias Roomy.Constants.RoomType
  alias Roomy.Constants.MessageType
  alias Roomy.Constants.InvitationStatus

  require RoomType
  require MessageType
  require InvitationStatus

  describe "when creating a room of type `group`" do
    test "if none of the users are friends with the sender, all receive invitations", %{
      user1: user1
    } do
      [
        {:ok, %User{} = user2},
        {:ok, %User{} = user3},
        {:ok, %User{} = user4} | _
      ] =
        [
          %Request.RegisterUser{
            display_name: "Peter Winchester",
            username: "pete",
            password: "123456"
          },
          %Request.RegisterUser{
            display_name: "Steven Turner",
            username: "steve",
            password: "123456"
          },
          %Request.RegisterUser{
            display_name: "Garry Simpson",
            username: "garry",
            password: "123456"
          }
        ]
        |> Enum.map(fn request ->
          Account.register_user(request)
        end)

      room_name = "School group"
      invitation_message = "I'm making this group to connect with my school mates"

      assert {:ok, %Room{id: room_id, name: room_name}} =
               Account.create_group_chat(%Request.CreateGroupChat{
                 name: room_name,
                 sender_id: user1.id,
                 invitation_message: invitation_message,
                 participants_usernames: [user2.username, user3.username, user4.username]
               })

      Enum.each([user2, user3, user4], fn %User{id: user_id} ->
        {:ok, %User{received_invitations: [invitation]}} =
          User.get(user_id, received_invitations: :room)

        assert strip_unnecessary_fields(invitation) == %{
                 room_id: room_id,
                 sender_id: user1.id,
                 message: invitation_message,
                 status: InvitationStatus.pending(),
                 room: %{
                   id: room_id,
                   name: room_name,
                   type: RoomType.group()
                 }
               }
      end)
    end

    test "if all of the users are friends with the sender, they are all added to the chat group",
         %{
           user1: user1
         } do
      [
        {:ok, %User{} = user2},
        {:ok, %User{} = user3},
        {:ok, %User{} = user4} | _
      ] =
        [
          %Request.RegisterUser{
            display_name: "Peter Winchester",
            username: "pete",
            password: "123456"
          },
          %Request.RegisterUser{
            display_name: "Steven Turner",
            username: "steve",
            password: "123456"
          },
          %Request.RegisterUser{
            display_name: "Garry Simpson",
            username: "garry",
            password: "123456"
          }
        ]
        |> Enum.map(fn request ->
          Account.register_user(request)
        end)

      {:ok, %Invitation{} = fr_request1} =
        Account.send_friend_request(%Request.SendFriendRequest{
          sender_id: user1.id,
          receiver_username: user2.username
        })

      {:ok, %Invitation{} = fr_request2} =
        Account.send_friend_request(%Request.SendFriendRequest{
          sender_id: user1.id,
          receiver_username: user3.username
        })

      {:ok, %Invitation{} = fr_request3} =
        Account.send_friend_request(%Request.SendFriendRequest{
          sender_id: user1.id,
          receiver_username: user4.username
        })

      {:ok, _} = Account.answer_invitation(fr_request1.id, true)
      {:ok, _} = Account.answer_invitation(fr_request2.id, true)
      {:ok, _} = Account.answer_invitation(fr_request3.id, true)

      room_name = "School group"
      invitation_message = "I'm making this group to connect with my school mates"

      assert {:ok, %Room{id: room_id}} =
               Account.create_group_chat(%Request.CreateGroupChat{
                 name: room_name,
                 sender_id: user1.id,
                 invitation_message: invitation_message,
                 participants_usernames: [user2.username, user3.username, user4.username]
               })

      Enum.each([user2, user3, user4], fn %User{id: user_id} ->
        {:ok, %User{rooms: rooms}} = User.get(user_id, :rooms)

        group_room = Enum.find(rooms, fn %Room{id: id} -> id == room_id end)

        assert strip_unnecessary_fields(group_room) == %{
                 id: room_id,
                 name: room_name,
                 type: RoomType.group()
               }
      end)
    end

    test "friends of the sender should join the room and non friends should receive invitation",
         %{
           user1: user1
         } do
      [
        {:ok, %User{} = user2},
        {:ok, %User{} = user3},
        {:ok, %User{} = user4} | _
      ] =
        [
          %Request.RegisterUser{
            display_name: "Peter Winchester",
            username: "pete",
            password: "123456"
          },
          %Request.RegisterUser{
            display_name: "Steven Turner",
            username: "steve",
            password: "123456"
          },
          %Request.RegisterUser{
            display_name: "Garry Simpson",
            username: "garry",
            password: "123456"
          }
        ]
        |> Enum.map(fn request ->
          Account.register_user(request)
        end)

      {:ok, %Invitation{} = fr_request1} =
        Account.send_friend_request(%Request.SendFriendRequest{
          sender_id: user1.id,
          receiver_username: user2.username
        })

      {:ok, %Invitation{} = fr_request2} =
        Account.send_friend_request(%Request.SendFriendRequest{
          sender_id: user1.id,
          receiver_username: user3.username
        })

      {:ok, _} = Account.answer_invitation(fr_request1.id, true)
      {:ok, _} = Account.answer_invitation(fr_request2.id, true)

      room_name = "School group"
      invitation_message = "I'm making this group to connect with my school mates"

      assert {:ok, %Room{id: room_id}} =
               Account.create_group_chat(%Request.CreateGroupChat{
                 name: room_name,
                 sender_id: user1.id,
                 invitation_message: invitation_message,
                 participants_usernames: [user2.username, user3.username, user4.username]
               })

      # Friends of the Sender should be already in the Room
      Enum.each([user2, user3], fn %User{id: user_id} ->
        {:ok, %User{rooms: rooms}} = User.get(user_id, :rooms)

        group_room = Enum.find(rooms, fn %Room{id: id} -> id == room_id end)

        assert strip_unnecessary_fields(group_room) == %{
                 id: room_id,
                 name: room_name,
                 type: RoomType.group()
               }
      end)

      # Non-Friends of the Sender should receive invitation to join the Group
      Enum.each([user4], fn %User{id: user_id} ->
        {:ok, %User{received_invitations: [invitation]}} =
          User.get(user_id, received_invitations: :room)

        assert strip_unnecessary_fields(invitation) == %{
                 room_id: room_id,
                 sender_id: user1.id,
                 message: invitation_message,
                 status: InvitationStatus.pending(),
                 room: %{
                   id: room_id,
                   name: room_name,
                   type: RoomType.group()
                 }
               }
      end)
    end

    test "when invited user to group joins, a system message appears",
         %{
           user1: user1
         } do
      [
        {:ok, %User{} = user2} | _
      ] =
        [
          %Request.RegisterUser{
            display_name: "Peter Winchester",
            username: "pete",
            password: "123456"
          }
        ]
        |> Enum.map(fn request ->
          Account.register_user(request)
        end)

      room_name = "School group"
      invitation_message = "I'm making this group to connect with my school mates"

      assert {:ok, %Room{id: room_id}} =
               Account.create_group_chat(%Request.CreateGroupChat{
                 name: room_name,
                 sender_id: user1.id,
                 invitation_message: invitation_message,
                 participants_usernames: [user2.username]
               })

      {:ok, %User{received_invitations: [%Invitation{id: invitation_id}]}} =
        User.get(user2.id, received_invitations: :room)

      {:ok, %Invitation{}} = Account.answer_invitation(invitation_id, true)

      {:ok, %Room{messages: [message]}} = Room.get(room_id, :messages)

      assert strip_unnecessary_fields(message) == %{
               type: MessageType.system_group_join(),
               content: "User #{user2.display_name} has joined the group",
               deleted: false,
               edited: false,
               edited_at: nil,
               sender_id: nil,
               room_id: room_id
             }
    end
  end

  defp strip_unnecessary_fields(%Invitation{} = entry) do
    invitation =
      entry
      |> Map.from_struct()
      |> Map.delete(:id)
      |> Map.delete(:__meta__)
      |> Map.delete(:sender)
      |> Map.delete(:receiver)
      |> Map.delete(:receiver_id)
      |> Map.delete(:updated_at)
      |> Map.delete(:inserted_at)

    %{
      invitation
      | room:
          entry.room
          |> Map.from_struct()
          |> Map.delete(:__meta__)
          |> Map.delete(:inserted_at)
          |> Map.delete(:updated_at)
          |> Map.delete(:users)
          |> Map.delete(:messages)
    }
  end

  defp strip_unnecessary_fields(%Room{} = entry) do
    entry
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Map.delete(:inserted_at)
    |> Map.delete(:updated_at)
    |> Map.delete(:users)
    |> Map.delete(:messages)
  end

  defp strip_unnecessary_fields(%Message{} = entry) do
    entry
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Map.delete(:id)
    |> Map.delete(:room)
    |> Map.delete(:sender)
    |> Map.delete(:inserted_at)
    |> Map.delete(:updated_at)
    |> Map.delete(:users_messages)
    |> Map.delete(:sent_at)
  end
end
