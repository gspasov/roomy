defmodule Roomy.Constants.FriendRequestStatus do
  @moduledoc false

  defmacro pending do
    quote do
      "pending"
    end
  end

  defmacro rejected do
    quote do
      "rejected"
    end
  end

  defmacro accepted do
    quote do
      "accepted"
    end
  end

  defguard is_allowed_status(status) when status in [pending(), accepted(), rejected()]
end
