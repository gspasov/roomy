defmodule Roomy.Utils do
  @moduledoc false

  @spec execute_after(pos_integer(), (() -> result)) :: result when result: any()
  def execute_after(time, fun) when is_integer(time) do
    Process.send_after(self(), :run, time)

    receive do
      :run -> fun.()
    end
  end

  @doc """
  Can be used when calling boolean expressions in `with` statement

  ## Example:
      with {:ok, true} <- check(true, :some_reason) do
        :ok
      else
        {:error, :some_reason} -> :error
      end
  """
  @spec check(boolean(), error) :: {:ok, true} | {:error, error} when error: atom()
  def check(boolean, error)

  def check(true, _) do
    {:ok, true}
  end

  def check(false, error) do
    {:error, error}
  end
end
