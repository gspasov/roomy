defmodule Roomy.Bus.Topic do
  @moduledoc """
  Describes all valid topics to publish to via the BUS
  """

  @spec all() :: Macro.t()
  defmacro all() do
    quote do
      "roomy"
    end
  end

  @spec room(room_id :: String.t()) :: Macro.t()
  defmacro room(room_id) do
    quote do
      "roomy/chat/#{unquote(room_id)}"
    end
  end

  @spec user(user_id :: pos_integer()) :: Macro.t()
  defmacro user(user_id) do
    quote do
      "roomy/user/#{unquote(user_id)}/#"
    end
  end

  @spec invitation_all(user_id :: pos_integer()) :: Macro.t()
  defmacro invitation_all(user_id) do
    quote do
      "roomy/user/#{unquote(user_id)}/invitation/#"
    end
  end

  @spec invitation_request(user_id :: pos_integer(), invitation_id :: pos_integer()) :: Macro.t()
  defmacro invitation_request(user_id, invitation_id) do
    quote do
      "roomy/user/#{unquote(user_id)}/invitation/#{unquote(invitation_id)}/request"
    end
  end

  @spec invitation_response(user_id :: pos_integer(), invitation_id :: pos_integer()) :: Macro.t()
  defmacro invitation_response(user_id, invitation_id) do
    quote do
      "roomy/user/#{unquote(user_id)}/invitation/#{unquote(invitation_id)}/response"
    end
  end

  @spec invitation_response_all(user_id :: pos_integer()) :: Macro.t()
  defmacro invitation_response_all(user_id) do
    quote do
      "roomy/user/#{unquote(user_id)}/invitation/+/response"
    end
  end

  @spec system() :: Macro.t()
  defmacro system() do
    quote do
      "roomy/system"
    end
  end
end
