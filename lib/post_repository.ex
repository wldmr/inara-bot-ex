defmodule PostRepository do
  @callback fetch_latest(Post.t() | nil) :: list(Post.t())
  @callback send_reply(Reply.t()) :: :ok | {:error, term()}
end
