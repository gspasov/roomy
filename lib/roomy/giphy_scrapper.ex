defmodule Roomy.GiphyScrapper do
  alias Roomy.Giphy
  use GenServer

  @table_filename "gif_v2.ets"
  @table_name :giphy

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def info do
    GenServer.call(__MODULE__, :info)
  end

  def get_gifs do
    ets_table_dir_path = Path.join([File.cwd!(), "priv", "static", "gif_database"])

    ets_table_file_path =
      [ets_table_dir_path, @table_filename]
      |> Path.join()
      |> String.to_charlist()

    :ets.file2tab(ets_table_file_path)
    Enum.map(:ets.tab2list(@table_name), fn {_, _, gif} -> gif end)
  end

  @impl true
  def init([]) do
    todo = [
      "Bored",
      "Duh",
      "Eww",
      "Annoyed",
      "Grumpy",
      "Happy",
      "Okay",
      "Sure",
      "No",
      "Yikes",
      "Oops",
      "Meh",
      "Wow",
      "Ugh",
      "LOL",
      "Whatever",
      "Seriously",
      "Fine",
      "Cheers",
      "HellNo",
      "Oops",
      "Yikes",
      "Cheers",
      "Alright",
      "Please",
      "Thanks",
      "Dang",
      "Really",
      "Wait",
      "Grr",
      "Sheesh",
      "Sure",
      "Bye",
      "Sorry",
      "Uh-oh",
      "Wink",
      "Nope",
      "Fine",
      "Quiet",
      "Done",
      "Whatever",
      "Whoa",
      "Nice",
      "Perfect",
      "Hungry",
      "Sleepy",
      "Bravo",
      "Wait",
      "Gross",
      "Oopsie",
      "Jealous",
      "Shocked",
      "Lazy",
      "Crazy",
      "Lit",
      "Uptight",
      "Chill",
      "Curious",
      "Furious",
      "Victory",
      "Deadline",
      "Focus",
      "Meeting",
      "Lunch",
      "Report",
      "Teamwork",
      "Coffee",
      "Overtime",
      "Break",
      "Approval",
      "Stressed",
      "Review",
      "Presentation",
      "Brainstorm",
      "Multitask",
      "Done",
      "Hustle",
      "Feedback",
      "Inbox",
      "Success"
    ]

    Process.send(Process.whereis(__MODULE__), :scrape, [])

    ets_table_dir_path = Path.join([File.cwd!(), "priv", "static", "gif_database"])

    ets_table_file_path =
      [ets_table_dir_path, @table_filename]
      |> Path.join()
      |> String.to_charlist()

    with :ok <- File.mkdir_p(ets_table_dir_path),
         {:error, _reason} <- :ets.file2tab(ets_table_file_path) do
      :ets.new(@table_name, [:set, :named_table, read_concurrency: true])
    else
      error ->
        IO.inspect(error, label: "Error on init")
    end

    {:ok,
     %{
       todo: todo,
       done: [],
       client: Giphy.client(),
       ets_table_file_path: ets_table_file_path,
       offset: 100
     }}
  end

  @impl true
  def handle_call(:info, _, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:scrape, %{todo: [], done: done, offset: offset} = state) do
    IO.inspect("================== DONE with offset #{offset} ==================")
    Process.send(self(), :scrape, [])
    {:noreply, %{state | todo: done, done: [], offset: offset + 50}}
  end

  @impl true
  def handle_info(
        :scrape,
        %{
          client: client,
          todo: [search_string | rest],
          done: done,
          ets_table_file_path: ets_table_file_path,
          offset: offset
        } = state
      ) do
    IO.inspect("Getting #{search_string}")

    new_state =
      case Giphy.search(client, %{q: search_string, limit: 50, offset: offset}) do
        {:ok, gifs} ->
          Process.send(self(), :scrape, [])
          store_in_ets(@table_name, search_string, gifs, ets_table_file_path)
          %{state | todo: rest, done: [search_string | done]}

        :error ->
          Process.send_after(self(), :scrape, :timer.minutes(65))
          state
      end

    {:noreply, new_state}
  end

  defp store_in_ets(table, search_string, gifs, ets_table_file_path) do
    Enum.each(gifs, fn %Giphy{id: id} = gif ->
      :ets.insert(table, {id, search_string, gif})
    end)

    :ok = :ets.tab2file(@table_name, ets_table_file_path)
  end
end
