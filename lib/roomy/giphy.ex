defmodule Roomy.Giphy do
  use TypedStruct

  require Logger

  @api_key Application.compile_env(:roomy, :giphy)[:api_key]
  @required_params %{api_key: @api_key}
  @default_params %{limit: 2}

  typedstruct required: true do
    field(:title, String.t())
    field(:medium_url, String.t())
    field(:medium_height, pos_integer())
    field(:medium_width, pos_integer())
    field(:preview_url, String.t())
    field(:preview_height, pos_integer())
    field(:preview_width, pos_integer())
  end

  def client() do
    middleware = [
      Tesla.Middleware.JSON,
      {Tesla.Middleware.BaseUrl, "https://api.giphy.com/v1/gifs"}
    ]

    Tesla.client(middleware)
  end

  def trending_gifs(client, params \\ @default_params) do
    query_params = params |> Map.merge(@required_params) |> URI.encode_query()

    case Tesla.get(client, "/trending?#{query_params}") do
      {:ok, %Tesla.Env{status: 200, body: %{"data" => data}}} ->
        {:ok,
         Enum.map(data, fn %{
                             "title" => title,
                             "images" => %{
                               "fixed_width" => %{
                                 "height" => medium_height,
                                 "width" => medium_width,
                                 "url" => medium_url
                               },
                               "fixed_width_downsampled" => %{
                                 "height" => preview_height,
                                 "width" => preview_width,
                                 "url" => preview_url
                               }
                             }
                           } ->
           %__MODULE__{
             title: title,
             medium_height: medium_height,
             medium_width: medium_width,
             medium_url: medium_url,
             preview_height: preview_height,
             preview_width: preview_width,
             preview_url: preview_url
           }
         end)}

      error ->
        Logger.error("[#{__MODULE__}] #{inspect(error)}")
        :error
    end
  end
end
