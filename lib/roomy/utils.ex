defmodule Roomy.Utils do
  @moduledoc false

  @spec execute_after(pos_integer(), (() -> result)) :: result when result: any()
  def execute_after(time, fun) when is_integer(time) do
    Process.send_after(self(), :run, time)

    receive do
      :run -> fun.()
    end
  end
end
