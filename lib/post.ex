defmodule Post do
  @type t :: %__MODULE__{
          id: String.t(),
          username: String.t(),
          heading: String.t(),
          body: String.t(),
          timestamp: DateTime.t()
        }
  @enforce_keys [:id, :username, :body, :timestamp]
  defstruct [:id, :username, :heading, :body, :timestamp]
end
