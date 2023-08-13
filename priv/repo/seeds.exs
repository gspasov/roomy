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
alias Roomy.Models.FriendRequest

[{:ok, %User{} = user1}, {:ok, %User{} = user2}, {:ok, %User{} = user3} | _] =
  [
    %Request.RegisterUser{
      display_name: "Georgi Spasov",
      username: "gspasov",
      password: "123456"
    },
    %Request.RegisterUser{
      display_name: "Pesho Machinata",
      username: "peshaka",
      password: "123456"
    },
    %Request.RegisterUser{
      display_name: "Miro Kacata",
      username: "mcaka",
      password: "123456"
    }
  ]
  |> Enum.map(fn request ->
    Account.register_user(request)
  end)

{:ok, %FriendRequest{} = fr_request1} =
  Account.send_friend_request(%Request.SendFriendRequest{
    sender_id: user1.id,
    receiver_username: user2.username
  })

Account.answer_friend_request(fr_request1.id, true)

{:ok, %Room{id: room_id}} = Room.get_by(name: Account.build_room_name(user1.id, user2.id))

[
  {"hi", user1.id, true},
  {"hi to you too", user2.id, true},
  {"how are you doing?", user1.id, true},
  {"what are you up to?", user1.id, true},
  {"I'm pretty okay", user2.id, false},
  {"I'll be going to the movies tonight", user2.id, false},
  {"How about you?", user2.id, false},
  {"What is going in your life?", user2.id, false}
]
|> Enum.each(fn {message, user_id, seen?} ->
  {:ok, %Message{id: message_id}} =
    Account.send_message(%Request.SendMessage{
      content: message,
      sender_id: user_id,
      room_id: room_id,
      sent_at: DateTime.utc_now()
    })

  reader_id = if user_id == user1.id, do: user2.id, else: user1.id

  if seen? do
    Account.read_message(%Request.ReadMessage{message_id: message_id, reader_id: reader_id})
  end
end)
