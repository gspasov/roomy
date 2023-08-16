defmodule Roomy.Constants.RoomType do
  @moduledoc false

  defmacro dm do
    quote do
      "dm"
    end
  end

  defmacro group do
    quote do
      "group"
    end
  end
end
