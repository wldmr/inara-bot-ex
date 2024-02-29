defmodule PostRepository.Reddit do
  alias PostRepository.Reddit
  require Logger
  use Util.Sections

  @behaviour PostRepository

  use Supervisor

  @impl PostRepository
  def fetch_latest(identity, forum, latest_so_far \\ nil) do
    uri = URI.new!("/r/#{forum.name}/comments")

    uri =
      if latest_so_far,
        do: URI.append_query(uri, URI.encode_query(before: latest_so_far)),
        else: uri

    response = Reddit.Auth.get!(identity, uri)

    defsection :ignored, "Inspect Comment fields" do
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

  @impl PostRepository
  def send_post(identity, reply) do
    Logger.debug(
      "I would send the reply #{inspect(reply)} as #{inspect(identity)}, but that's not implemented yet."
    )

    :ok
  end

  @spec start_link(keyword()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(identity) do
    Supervisor.start_link(__MODULE__, identity)
  end

  @impl Supervisor
  def init(identity) do
    children = [
      {Reddit.Auth, identity}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
