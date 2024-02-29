defmodule PostRepository do
  defmodule Handle do
    @type t :: %{module: PostRepository.implementation(), identity: atom()}
    @enforce_keys [:module, :identity]
    defstruct [:module, :identity]

    def new(module, identity) do
      %__MODULE__{module: module, identity: identity}
    end
  end

  defimpl String.Chars, for: Handle do
    def to_string(this) do
      impl =
        this.module
        |> Atom.to_string()
        |> String.split(".")
        |> Enum.at(-1)
        |> String.downcase()

      identity = this.identity
      |> Atom.to_string()
      |> String.replace("_", "-")

      "#{impl}-#{identity}"
    end
  end

  @type implementation :: module()
  @type identity :: atom()

  @callback fetch_latest(identity(), Domain.Forum.t(), Domain.Post.id() | nil) :: list(Post.t())
  @callback send_post(identity(), Domain.Post.t()) :: :ok | {:error, term()}

  @spec fetch_latest(Handle.t(), Domain.Forum.t(), Domain.Post.id() | nil) :: list(Post.t())
  def fetch_latest(%Handle{module: repo, identity: identity}, forum, latest),
    do: repo.fetch_latest(identity, forum, latest)

  @spec send_post(Handle.t(), Domain.Post.t()) :: :ok | {:error, term()}
  def send_post(%Handle{module: repo, identity: identity}, post),
    do: repo.send_post(identity, post)
end
