defmodule Infra.Reddit.Api do
  require Logger
  use Util.Sections

  alias Infra.Reddit.Client

  @behaviour Domain.PostRepository

  use Supervisor

  @singleton_process __MODULE__

  @impl Domain.PostRepository
  @spec fetch_latest(Domain.Forum.id(), Domain.Post.id() | nil) :: list(Post.t())
  def fetch_latest(forum, latest_so_far \\ nil) do
    uri = URI.new!("/r/#{forum.name}/comments")

    uri =
      if latest_so_far,
        do: uri |> URI.append_query(URI.encode_query(before: latest_so_far)),
        else: uri

    response = Client.get!(uri)

    defsection "Inspect Comment fields" do
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
      %Domain.Post{
        id: "#{kind}_#{post["id"]}",
        username: post["author"],
        parent: post["parent_id"],
        heading: nil,
        body: post["body"],
        timestamp: post["created"] |> trunc() |> DateTime.from_unix!()
      }
    end)
  end

  @impl Domain.PostRepository
  @spec send_post(Domain.Post.t()) :: :ok | {:error, term()}
  def send_post(reply) do
    Logger.debug("I would send the reply #{inspect(reply)}, but that's not implemented yet.")
    :ok
  end

  @spec start_link(keyword()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opt \\ []) do
    Supervisor.start_link(__MODULE__, [], Keyword.merge(opt, name: @singleton_process))
  end

  @impl Supervisor
  def init(_init_arg) do
    children = [Client]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
