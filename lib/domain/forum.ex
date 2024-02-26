defmodule Domain.Forum do
  @opaque id :: binary()

  @type t() :: %__MODULE__{
          name: String.t()
        }

  defstruct [:name]
end
