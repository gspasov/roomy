# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Roomy.Repo.insert!(%Roomy.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Roomy.Account
alias Roomy.Request
alias Roomy.Models.User
alias Roomy.Models.Room
alias Roomy.Models.Message
alias Roomy.Models.Invitation
alias Roomy.Constants.RoomType

require RoomType

[
  {:ok, %User{} = user1},
  {:ok, %User{} = user2},
  {:ok, %User{} = user3},
  {:ok, %User{} = user4} | _
] =
  [
    %{
      display_name: "John Benton",
      username: "john",
      password: "123456"
    },
    %{
      display_name: "Peter Winchester",
      username: "pete",
      password: "123456"
    },
    %{
      display_name: "Steven Turner",
      username: "steve",
      password: "123456"
    },
    %{
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

{:ok, %Room{id: room_id}} = Room.get_by(name: Account.build_room_name(user1.id, user2.id))
{:ok, %Room{id: room_id_2}} = Room.get_by(name: Account.build_room_name(user1.id, user3.id))

{:ok, %Message{}} =
  Account.send_message(%Request.SendMessage{
    content: "how are you my friend?",
    sender_id: user1.id,
    room_id: room_id_2,
    sent_at: DateTime.utc_now()
  })

[
  {"Nulla pharetra diam", user1.id, true},
  {"Eget est lorem ipsum", user2.id, true},
  {"condimentum id venenatis a", user1.id, true},
  {"ermentum leo vel orci porta", user1.id, true},
  {"ulputate ut pharetra sit ametkay", user2.id, true},
  {" risus sed vulputate", user2.id, true},
  {"Morbi tristique senectus et netus et", user1.id, true},
  {"Malesuada fames ac turpis egestas integer eget aliquet nibh. Viverra adipiscing at in tellus integer feugiat scelerisque",
   user1.id, true},
  {"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
   user2.id, true},
  {"Facilisi nullam vehicula ipsum a arcu cursus", user1.id, true},
  {"nibh ipsum consequat nisl vel pretium", user2.id, true},
  {"luctus accumsan. Id diam ", user1.id, true},
  {"etium nibh ipsum consequat nisl", user1.id, true},
  {"sit amet cursus sit amet dictum", user2.id, true},
  {"Magna sit amet purus gravida quis", user1.id, true},
  {"Aliquet nec ullamcorper sit amet", user2.id, false}
]
|> Enum.each(fn {message, sender_id, seen?} ->
  {:ok, %Message{id: message_id}} =
    Account.send_message(%Request.SendMessage{
      content: message,
      sender_id: sender_id,
      room_id: room_id,
      sent_at: DateTime.utc_now()
    })

  reader_id =
    if sender_id == user1.id do
      user2.id
    else
      user1.id
    end

  if seen? do
    :ok = Account.read_message(%Request.ReadMessage{message_id: message_id, reader_id: reader_id})
  end
end)
