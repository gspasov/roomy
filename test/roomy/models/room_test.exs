defmodule Roomy.Models.RoomTest do
  use Roomy.DataCase, async: true

  alias Roomy.Request
  alias Roomy.Account
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.Invitation
  alias Roomy.Constants.RoomType
  alias Roomy.Constants.InvitationStatus

  require RoomType
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
                 participants_usernames: ["pete", "steve", "garry"]
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
                 participants_usernames: ["pete", "steve", "garry"]
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
                 participants_usernames: ["pete", "steve", "garry"]
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
  end

  defp strip_unnecessary_fields(%Invitation{} = entity) do
    invitation =
      entity
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
          entity.room
          |> Map.from_struct()
          |> Map.delete(:__meta__)
          |> Map.delete(:inserted_at)
          |> Map.delete(:updated_at)
          |> Map.delete(:users)
    }
  end

  defp strip_unnecessary_fields(%Room{} = entity) do
    entity
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Map.delete(:inserted_at)
    |> Map.delete(:updated_at)
    |> Map.delete(:users)
  end
end
