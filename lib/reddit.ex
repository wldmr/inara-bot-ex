defmodule Reddit do
  require Logger
  use Util.Sections

  def fetch_latest(identity, subreddit, latest_so_far \\ nil) do
    uri = URI.new!("/r/#{subreddit}/comments")

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
      %Post{
        id: "#{kind}_#{post["id"]}",
        username: post["author"],
        parent: post["parent_id"],
        heading: nil,
        body: post["body"],
        timestamp: post["created"] |> trunc() |> DateTime.from_unix!()
      }
    end)
  end

  def send_post(identity, post) do
    Logger.debug(
      "I would send the reply #{inspect(post)} as #{inspect(identity)}, but that's not implemented yet."
    )

    :ok
  end

  @spec start_link(keyword()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(identity) do
    Supervisor.start_link(__MODULE__, identity, name: String.to_atom("#{__MODULE__}.#{identity}"))
  end
end
