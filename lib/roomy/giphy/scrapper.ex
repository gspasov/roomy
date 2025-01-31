defmodule Roomy.Giphy.Scrapper do
  use GenServer

  alias Roomy.Giphy

  @table_filename "gif_v2.ets"
  @table_name :giphy

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, todos(), name: __MODULE__)
  end

  def info do
    GenServer.call(__MODULE__, :info)
  end

  def load_table do
    ets_table_dir_path()
    |> ets_table_file_path(@table_filename)
    |> :ets.file2tab()
  end

  def get_items(limit, start_id \\ nil) do
    start_id = start_id || :ets.first(@table_name)
    match_spec = [{{:"$1", :"$2", :"$3"}, [{:>, :"$1", start_id}], [:"$3"]}]

    case :ets.select(@table_name, match_spec, limit) do
      {items, {_table, next_item_id, _, _, _, _, _, _}} -> {items, next_item_id}
      {items, :"$end_of_table"} -> {items, nil}
    end
  end

  @impl true
  def init(todos) do
    ets_table_dir_path = ets_table_dir_path()
    ets_table_file_path = ets_table_file_path(ets_table_dir_path, @table_filename)

    :ok = File.mkdir_p(ets_table_dir_path)

    with {:error, _reason} <- :ets.file2tab(ets_table_file_path) do
      :ets.new(@table_name, [:ordered_set, :named_table, read_concurrency: true])
    end

    Process.send(self(), :scrape, [])

    {:ok,
     %{
       todo: todos,
       done: [],
       client: Giphy.Client.client(),
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
    Logger.info("================== DONE with offset #{offset} ==================")
    Process.send(self(), :scrape, [])
    # Continue scraping the next batch of the same words
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
    Logger.info("Getting #{search_string}")

    new_state =
      case Giphy.Client.search(client, %{q: search_string, limit: 50, offset: offset}) do
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

  defp ets_table_dir_path do
    Path.join([File.cwd!(), "priv", "static", "gif_database"])
  end

  defp ets_table_file_path(dir_path, file_name) do
    [dir_path, file_name]
    |> Path.join()
    |> String.to_charlist()
  end

  defp todos do
    [
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
  end
end
