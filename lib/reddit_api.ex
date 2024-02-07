defmodule Reddit.Api do
  require Logger
  use Util.Sections

  # Behaves like a repository
  @behaviour PostRepository

  # uses other processes under the hood; clients don't need to know this.
  use Supervisor

  @singleton_process __MODULE__

  @impl PostRepository
  @spec fetch_latest(Post.t() | nil) :: list(Post.t())
  def fetch_latest(latest_so_far) do
    uri = URI.new!("/r/firefly/comments")

    uri = if latest_so_far, do: URI.append_query(uri, "before=#{latest_so_far.id}"), else: uri

    response = Reddit.Client.get!(uri)

    defsection ignored: "Inspect Comment fields" do
      # In case you want to quickly inspect the fields in a comment.
      Logger.debug(
        "Comment fields: " <>
          (Enum.flat_map(response.body["data"]["children"], &Map.keys(&1["data"]))
           |> Enum.uniq()
           |> Enum.join(", "))
      )
    end

    response.body["data"]["children"]
    |> Enum.map(&{&1["kind"], &1["data"]})
    |> Enum.map(fn {kind, post} ->
      %Post{
        id: "#{kind}_#{post["id"]}",
        username: post["author"],
        heading: nil,
        body: post["body"],
        timestamp: post["created"] |> trunc() |> DateTime.from_unix!()
      }
    end)
  end

  @impl PostRepository
  @spec send_reply(Reply.t()) :: :ok | {:error, term()}
  def send_reply(reply) do
    Logger.debug("I would send the reply #{reply}, but that's not implemented yet.")
    :ok
  end

  @spec start_link(keyword()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opt \\ []) do
    Supervisor.start_link(__MODULE__, [], Keyword.merge(opt, name: @singleton_process))
  end

  @impl Supervisor
  def init(_init_arg) do
    children = [Reddit.Client]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
