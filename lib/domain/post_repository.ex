defmodule Domain.PostRepository do
  @type t :: module()
  @callback fetch_latest(Domain.Forum.id(), Domain.Post.id() | nil) :: list(Post.t())
  @callback send_post(Domain.Post.t()) :: :ok | {:error, term()}
end
