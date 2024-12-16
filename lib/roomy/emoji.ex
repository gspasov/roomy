defmodule Roomy.Emoji do
  use TypedStruct

  @version "16.0.0"
  @host "cdn.jsdelivr.net"
  @base_path "npm/emojibase-data"
  @emojis_path "#{@base_path}@#{@version}/en/compact.json"
  @shortcodes_path "#{@base_path}@#{@version}/en/shortcodes/iamcal.json"
  @table_filename "#{@version}.ets"
  @lookup_table :emojis_lookup

  alias Roomy.Utils

  require Logger

  typedstruct required: true do
    field(:group, non_neg_integer())
    field(:order, pos_integer())
    field(:shortcode, String.t())
    field(:hex_code, String.t())
    field(:unicode, String.t())
  end

  def load_table do
    ets_table_dir_path = Path.join([File.cwd!(), "priv", "static", "emoji_database"])

    ets_table_file_path =
      [ets_table_dir_path, @table_filename]
      |> Path.join()
      |> String.to_charlist()

    client = client()

    with :ok <- File.mkdir_p(ets_table_dir_path),
         {:error, _reason} <- :ets.file2tab(ets_table_file_path),
         {:ok, emojis} <- fetch_emojies(client),
         {:ok, shortcode_mappings} <- fetch_shortcodes(client) do
      generate_emojis_table(__MODULE__, emojis, shortcode_mappings)
      :ok = :ets.tab2file(__MODULE__, ets_table_file_path)
    end

    generate_lookup_table(@lookup_table)
  end

  def lookup(key) do
    :ets.select(@lookup_table, [{{key, :_}, [], [:"$_"]}])
  end

  def get_group(group) do
    :ets.select(__MODULE__, [{{{group, :_}, :_, :_, :_}, [], [:"$_"]}])
  end

  def get_groups do
    :ets.select(__MODULE__, [{{{:"$1", :_}, :_, :_, :_}, [], [:"$1"]}])
    |> Enum.uniq()
    |> Enum.into(%{}, fn group ->
      {group, group |> get_group() |> Enum.map(&to_struct/1)}
    end)
  end

  def replace_with(text, func) do
    emoji_unicodes =
      Enum.flat_map(get_groups(), fn {_group, emojis} ->
        Enum.map(emojis, fn %__MODULE__{unicode: unicode} -> unicode end)
      end)

    text
    |> String.graphemes()
    |> Enum.map(fn grapheme ->
      if Enum.member?(emoji_unicodes, grapheme) do
        func.(grapheme)
      else
        grapheme
      end
    end)
    |> Enum.join()
  end

  def generate_lookup_table(table) do
    :ets.new(table, [:bag, :named_table, read_concurrency: true])

    :ets.foldl(
      fn {{_group, _order}, shortcode, _hex_code, _unicode} = data, _ ->
        shortcode
        |> Utils.string_variations()
        |> Enum.each(fn section ->
          :ets.insert(table, {section, to_struct(data)})
        end)
      end,
      :ok,
      __MODULE__
    )
  end

  defp generate_emojis_table(table, emojis, shortcode_mappings) do
    :ets.new(table, [:ordered_set, :named_table, read_concurrency: true])

    Enum.each(emojis, fn %{"hexcode" => hex_code, "unicode" => unicode} = params ->
      shortcode_mappings
      |> Map.get(hex_code)
      |> List.wrap()
      |> Enum.each(fn shortcode ->
        key = {Map.get(params, "group"), Map.get(params, "order")}
        :ets.insert(table, {key, shortcode, hex_code, unicode})
      end)
    end)
  end

  defp client() do
    middleware = [
      Tesla.Middleware.JSON,
      {Tesla.Middleware.BaseUrl, "https://#{@host}"}
    ]

    Tesla.client(middleware)
  end

  defp fetch_emojies(client) do
    case Tesla.get(client, "/#{@emojis_path}") do
      {:ok, %Tesla.Env{status: 200, body: data}} ->
        {:ok, data}

      error ->
        Logger.error("[#{__MODULE__}] #{inspect(error)}")
        :error
    end
  end

  defp fetch_shortcodes(client) do
    case Tesla.get(client, "/#{@shortcodes_path}") do
      {:ok, %Tesla.Env{status: 200, body: data}} ->
        {:ok, data}

      error ->
        Logger.error("[#{__MODULE__}] #{inspect(error)}")
        :error
    end
  end

  defp to_struct({{group, order}, shortcode, hex_code, unicode}) do
    %__MODULE__{
      group: group,
      order: order,
      shortcode: shortcode,
      hex_code: hex_code,
      unicode: unicode
    }
  end
end
