defmodule Roomy.Utils do
  @human_readable_chars ~c"abcdefghjkmnprstuvwxyz3456789"

  def generate_code(code_length \\ 9) do
    1..code_length
    |> Enum.map(fn _ -> <<Enum.random(@human_readable_chars)>> end)
    |> Enum.chunk_every(div(code_length, 3))
    |> Enum.join("-")
  end

  def string_variations(string) do
    string
    |> String.to_charlist()
    |> do_string_variations([])
  end

  defp do_string_variations([], acc), do: acc

  defp do_string_variations([_ | t] = list, acc) do
    list
    |> Enum.with_index()
    |> Enum.reduce([], fn {_, index}, acc ->
      [to_string(Enum.drop(list, -index)) | acc]
    end)
    |> tl()
    |> Kernel.++(do_string_variations(t, acc))
  end
end
