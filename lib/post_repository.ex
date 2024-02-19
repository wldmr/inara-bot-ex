defmodule PostRepository do
  @type t :: module()
  @callback fetch_latest(Forum.id(), Post.id() | nil) :: list(Post.t())
  @callback send_post(Post.t()) :: :ok | {:error, term()}
end
