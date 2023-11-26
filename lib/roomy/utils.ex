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
  @spec check(boolean(), error) :: :ok | {:error, error} when error: atom()
  def check(boolean, error)

  def check(true, _) do
    :ok
  end

  def check(false, error) do
    {:error, error}
  end

  def parse_changeset_errors(%Ecto.Changeset{valid?: false, errors: errors} = changeset) do
    new_errors =
      Enum.map(errors, fn {field, {error_text, other}} ->
        field_name = field |> to_string |> separate_snake_case() |> String.capitalize()

        new_error_text =
          case error_text do
            "can't be blank" -> "#{field_name} is required"
            other -> "#{field_name} #{other}"
          end

        {field, {new_error_text, other}}
      end)

    %Ecto.Changeset{changeset | errors: new_errors}
  end

  def parse_changeset_errors(changeset), do: changeset

  defp separate_snake_case(snake_case) do
    snake_case
    |> String.split("_")
    |> Enum.join(" ")
  end
end
