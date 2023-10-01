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

alias Roomy.Repo
alias Roomy.Account
alias Roomy.Request
alias Roomy.Models.User
alias Roomy.Models.Room
alias Roomy.Models.Message
alias Roomy.Models.Invitation
alias Roomy.Constants.RoomType

require RoomType

users =
  [
    %{display_name: "John Benton", username: "john"},
    %{display_name: "Peter Winchester", username: "pete"},
    %{display_name: "Steven Turner", username: "steve"},
    %{display_name: "Garry Simpson", username: "garry"},
    %{display_name: "John Smith", username: "john_smith123"},
    %{display_name: "Mary Johnson", username: "mary_j"},
    %{display_name: "Robert Davis", username: "robert_d"},
    %{display_name: "Jennifer Wilson", username: "jennifer_w"},
    %{display_name: "Michael Brown", username: "michael_brown"},
    %{display_name: "Lisa Taylor", username: "lisa_taylor"},
    %{display_name: "William Lee", username: "william_lee"},
    %{display_name: "Karen Martinez", username: "karen_m"},
    %{display_name: "David Rodriguez", username: "david_rodriguez"},
    %{display_name: "Linda Anderson", username: "linda_a"},
    %{display_name: "Richard Johnson", username: "richard_j"},
    %{display_name: "Patricia Thomas", username: "patricia_t"},
    %{display_name: "James White", username: "james_white"},
    %{display_name: "Susan Harris", username: "susan_h"},
    %{display_name: "Charles Clark", username: "charles_c"},
    %{display_name: "Nancy Turner", username: "nancy_t"},
    %{display_name: "Matthew Lewis", username: "matthew_l"},
    %{display_name: "Laura Baker", username: "laura_b"},
    %{display_name: "Joseph Hill", username: "joseph_h"},
    %{display_name: "Sarah Walker", username: "sarah_w"},
    %{display_name: "Daniel King", username: "daniel_k"},
    %{display_name: "Karen Scott", username: "karen_s"},
    %{display_name: "Paul Green", username: "paul_g"},
    %{display_name: "Jessica Hall", username: "jessica_h"},
    %{display_name: "Brian Garcia", username: "brian_g"},
    %{display_name: "Cynthia Allen", username: "cynthia_a"},
    %{display_name: "Kevin Adams", username: "kevin_a"},
    %{display_name: "Carolyn Baker", username: "carolyn_b"},
    %{display_name: "Mark Miller", username: "mark_m"},
    %{display_name: "Rebecca Wright", username: "rebecca_w"},
    %{display_name: "Gary Martinez", username: "gary_m"},
    %{display_name: "Deborah Turner", username: "deborah_t"},
    %{display_name: "Steven Davis", username: "steven_d"},
    %{display_name: "Angela Harris", username: "angela_h"},
    %{display_name: "Edward Scott", username: "edward_s"},
    %{display_name: "Sharon Wilson", username: "sharon_w"},
    %{display_name: "George Lopez", username: "george_l"},
    %{display_name: "Donna Johnson", username: "donna_j"},
    %{display_name: "Kenneth Adams", username: "kenneth_a"},
    %{display_name: "Sandra Clark", username: "sandra_c"},
    %{display_name: "Christopher Young", username: "chris_y"},
    %{display_name: "Margaret White", username: "margaret_w"},
    %{display_name: "Timothy Lee", username: "timothy_l"},
    %{display_name: "Helen Mitchell", username: "helen_m"},
    %{display_name: "Larry Hall", username: "larry_h"},
    %{display_name: "Pamela Carter", username: "pamela_c"},
    %{display_name: "Jeffrey Thomas", username: "jeffrey_t"},
    %{display_name: "Betty Lewis", username: "betty_l"},
    %{display_name: "Ronald Anderson", username: "ronald_a"},
    %{display_name: "Debra Moore", username: "debra_m"},
    %{display_name: "Scott Turner", username: "scott_t"},
    %{display_name: "Dorothy Baker", username: "dorothy_b"},
    %{display_name: "Frank King", username: "frank_k"},
    %{display_name: "Donna Nelson", username: "donna_n"},
    %{display_name: "Andrew Martin", username: "andrew_m"},
    %{display_name: "Nancy Cook", username: "nancy_c"},
    %{display_name: "Raymond Turner", username: "raymond_t"},
    %{display_name: "Martha Garcia", username: "martha_g"},
    %{display_name: "Kenneth James", username: "kenneth_j"},
    %{display_name: "Ruth Turner", username: "ruth_t"},
    %{display_name: "Roger White", username: "roger_w"},
    %{display_name: "Carolyn Hall", username: "carolyn_h"},
    %{display_name: "Gerald Miller", username: "gerald_m"},
    %{display_name: "Janet Anderson", username: "janet_a"},
    %{display_name: "Henry Harris", username: "henry_h"},
    %{display_name: "Teresa Martinez", username: "teresa_m"},
    %{display_name: "Louis Walker", username: "louis_w"},
    %{display_name: "Gloria Thomas", username: "gloria_t"},
    %{display_name: "Keith Wright", username: "keith_w"},
    %{display_name: "Wanda Wilson", username: "wanda_w"},
    %{display_name: "Eugene Davis", username: "eugene_d"},
    %{display_name: "Diane Turner", username: "diane_t"},
    %{display_name: "Alan Scott", username: "alan_s"},
    %{display_name: "Rose Adams", username: "rose_a"},
    %{display_name: "Juan Clark", username: "juan_c"},
    %{display_name: "Marilyn Carter", username: "marilyn_c"},
    %{display_name: "Philip Young", username: "philip_y"},
    %{display_name: "Heather Hall", username: "heather_h"},
    %{display_name: "Earl Nelson", username: "earl_n"},
    %{display_name: "Sara King", username: "sara_k"},
    %{display_name: "Roger Johnson", username: "roger_j"},
    %{display_name: "Alice Turner", username: "alice_t"},
    %{display_name: "Patrick Smith", username: "patrick_s"},
    %{display_name: "Catherine Martin", username: "catherine_m"},
    %{display_name: "Jerry Davis", username: "jerry_d"},
    %{display_name: "Julie Harris", username: "julie_h"},
    %{display_name: "Larry Adams", username: "larry_a"},
    %{display_name: "Martha Clark", username: "martha_c"},
    %{display_name: "Roy Wilson", username: "roy_w"},
    %{display_name: "Shirley Lewis", username: "shirley_l"},
    %{display_name: "Bobby Martinez", username: "bobby_m"},
    %{display_name: "Teresa Baker", username: "teresa_b"},
    %{display_name: "Timothy Hall", username: "timothy_h"},
    %{display_name: "Rebecca Turner", username: "rebecca_t"},
    %{display_name: "Chris Johnson", username: "chris_j"},
    %{display_name: "Deborah Moore", username: "deborah_m"},
    %{display_name: "Larry Brown", username: "larry_b"},
    %{display_name: "Margaret Lewis", username: "margaret_l"},
    %{display_name: "Jeffrey Walker", username: "jeffrey_w"},
    %{display_name: "Barbara Scott", username: "barbara_s"}
  ]
  |> Enum.map(fn request -> Map.put(request, :hashed_password, User.hash_password("123456")) end)

{104, nil} = Repo.insert_all(User, users)

[
  %User{} = user1,
  %User{} = user2,
  %User{} = user3 | _
] = Repo.all(User)

{:ok, %Invitation{} = fr_request1} =
  Account.send_friend_request(%Request.SendFriendRequest{
    sender_id: user1.id,
    receiver_id: user2.id
  })

{:ok, %Invitation{} = fr_request2} =
  Account.send_friend_request(%Request.SendFriendRequest{
    sender_id: user1.id,
    receiver_id: user3.id
  })

{:ok, _} = Account.answer_invitation(fr_request1.id, true)
{:ok, _} = Account.answer_invitation(fr_request2.id, true)

{:ok, %Room{id: group_room_id}} =
  Account.create_group_chat(%Request.CreateGroupChat{
    participants_usernames: ["pete", "steve"],
    invitation_message: "Organization of party",
    name: "Party 2023",
    sender_id: user1.id
  })

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

[
  {"Nulla pharetra diam", user1.id, true},
  {"Eget est lorem ipsum", user2.id, true},
  {"condimentum id venenatis a", user3.id, true},
  {"ermentum leo vel orci porta", user3.id, true},
  {"ulputate ut pharetra sit ametkay", user2.id, true},
  {" risus sed vulputate", user2.id, true},
  {"Morbi tristique senectus et netus et", user1.id, true},
  {"Malesuada fames ac turpis egestas integer eget aliquet nibh. Viverra adipiscing at in tellus integer feugiat scelerisque",
   user1.id, true},
  {"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
   user2.id, true},
  {"Facilisi nullam vehicula ipsum a arcu cursus", user1.id, true},
  {"nibh ipsum consequat nisl vel pretium", user2.id, true},
  {"luctus accumsan. Id diam ", user3.id, true},
  {"etium nibh ipsum consequat nisl", user3.id, true},
  {"sit amet cursus sit amet dictum", user2.id, true},
  {"Magna sit amet purus gravida quis", user1.id, true},
  {"Aliquet nec ullamcorper sit amet", user3.id, false}
]
|> Enum.each(fn {message, sender_id, seen?} ->
  {:ok, %Message{id: message_id}} =
    Account.send_message(%Request.SendMessage{
      content: message,
      sender_id: sender_id,
      room_id: group_room_id,
      sent_at: DateTime.utc_now()
    })

  if seen? do
    to_see = [user1.id, user2.id, user3.id] -- [sender_id]

    Enum.each(to_see, fn user_id ->
      :ok = Account.read_message(%Request.ReadMessage{message_id: message_id, reader_id: user_id})
    end)
  end
end)
