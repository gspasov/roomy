defmodule Roomy.Giphy.Client do
  alias Roomy.HttpClient
  alias Roomy.Giphy

  require Logger

  @api_key Application.compile_env(:roomy, :giphy)[:api_key]
  @required_params %{api_key: @api_key}
  @default_params %{limit: 2}

  def client do
    HttpClient.new("https://api.giphy.com/v1/gifs")
  end

  def trending_gifs(client, params \\ @default_params) do
    query_params = params |> Map.merge(@required_params) |> URI.encode_query()

    case Tesla.get(client, "/trending?#{query_params}") do
      {:ok, %Tesla.Env{status: 200, body: %{"data" => data}}} ->
        {:ok,
         Enum.map(data, fn %{
                             "id" => id,
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
           %Giphy{
             id: id,
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

  def search(client, params) do
    query_params = params |> Map.merge(@required_params) |> URI.encode_query()

    case Tesla.get(client, "/search?#{query_params}") do
      {:ok, %Tesla.Env{status: 200, body: %{"data" => data}}} ->
        {:ok,
         Enum.map(data, fn %{
                             "id" => id,
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
           %Giphy{
             id: id,
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
