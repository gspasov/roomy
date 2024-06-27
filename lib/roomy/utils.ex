defmodule Roomy.Utils do
  @human_readable_chars ~c"abcdefghjkmnprstuvwxyz3456789"

  def generate_code(code_length \\ 9) do
    1..code_length
    |> Enum.map(fn _ -> <<Enum.random(@human_readable_chars)>> end)
    |> Enum.chunk_every(div(code_length, 3))
    |> Enum.join("-")
  end
end
