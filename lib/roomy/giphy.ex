defmodule Roomy.Giphy do
  use TypedStruct

  typedstruct required: true do
    field(:id, String.t())
    field(:title, String.t())
    field(:medium_url, String.t())
    field(:medium_height, pos_integer())
    field(:medium_width, pos_integer())
    field(:preview_url, String.t())
    field(:preview_height, pos_integer())
    field(:preview_width, pos_integer())
  end
end
