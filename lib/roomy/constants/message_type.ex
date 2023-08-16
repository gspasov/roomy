defmodule Roomy.Constants.MessageType do
  @moduledoc false

  defmacro system_group_join do
    quote do
      "system:group-join"
    end
  end

  defmacro system_group_leave do
    quote do
      "system:group-leave"
    end
  end

  defmacro normal do
    quote do
      "normal"
    end
  end
end
