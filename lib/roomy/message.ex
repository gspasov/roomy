defmodule Roomy.Message do
  use TypedStruct

  typedstruct do
    field(:type, :normal | :render, default: :normal)
    field(:sender, String.t())
    field(:content, binary())
    field(:sent_at, DateTime.t(), default: DateTime.utc_now())
  end
end
