defmodule Reply do
  @type t :: %__MODULE__{in_response_to: Post.t(), parts: nonempty_list(part())}
  @type part :: {:text, String.t()} | {:quote, URI.t(), String.t()}
  @enforce_keys [:in_response_to, :parts]
  defstruct [:in_response_to, :parts]
end
