defmodule Site do
  @type identity :: atom()
  @type forum :: String.t()
  @type latest_token :: term()
  @type impl :: atom()

  @callback fetch_latest(identity(), forum(), latest_token() | nil) ::
              {list(Post.t()), latest_token()}
  @callback send_post(atom(), Post.t()) :: Post.id()

  @behaviour Site

  @impl Site
  def fetch_latest(identity, forum, latest_token),
    do: impl(identity).fetch_latest(identity, forum, latest_token)

  @impl Site
  def send_post(identity, post),
    do: impl(identity).send_post(identity, post)

  defp impl(identity),
    do: Identity.site(identity)
end
