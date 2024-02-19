defmodule Forum do
  @opaque id :: binary()

  @type t() :: %__MODULE__{
          id: id(),
          name: String.t()
        }

  defstruct [:id, :name]
end
