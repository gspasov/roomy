defmodule Roomy.HttpClient do
  use Tesla

  def new(base_url \\ nil) do
    middleware =
      [
        base_url && {Tesla.Middleware.BaseUrl, base_url},
        Tesla.Middleware.JSON,
        Tesla.Middleware.FollowRedirects
      ]
      |> Enum.reject(&is_nil/1)

    adapter = {Tesla.Adapter.Hackney, follow_redirect: true}

    Tesla.client(middleware, adapter)
  end
end
