defmodule Reddit do
  require Logger
  use Util.Sections

  @opaque latest_token() :: %{comment: Post.id(), article: Post.id()}

  @comment_kind "t1_"
  @article_kind "t3_"

  @spec fetch_latest(atom(), String.t(), latest_token()) :: {list(Post.t()), latest_token()}
  def fetch_latest(identity, subreddit, latest_so_far \\ nil) do
    latest_comment = if latest_so_far, do: Map.get(latest_so_far, :comment), else: nil
    latest_article = if latest_so_far, do: Map.get(latest_so_far, :article), else: nil

    {comments, comment_token} = latest_comments(identity, subreddit, latest_comment)
    {articles, article_token} = latest_articles(identity, subreddit, latest_article)

    posts = articles ++ comments
    token = %{comment: comment_token, article: article_token}

    {posts, token}
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

  defp latest_comments(identity, subreddit, comment_token) do
    uri = URI.new!("/r/#{subreddit}/comments")

    uri =
      if comment_token,
        do: URI.append_query(uri, URI.encode_query(before: comment_token)),
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

    comments =
      response.body["data"]["children"]
      |> Enum.map(& &1["data"])
      |> Enum.map(fn post ->
        %Post{
          id: "#{@comment_kind}#{post["id"]}",
          username: post["author"],
          parent: post["parent_id"],
          heading: nil,
          body: post["body"],
          timestamp: post["created"] |> trunc() |> DateTime.from_unix!()
        }
      end)

    comment_token =
      comments
      |> Enum.max_by(& &1.timestamp, fn -> %{} end)
      |> Map.get(:id, comment_token)

    {comments, comment_token}
  end

  defp latest_articles(identity, subreddit, article_token) do
    uri = URI.new!("/r/#{subreddit}/new")

    uri =
      if article_token,
        do: URI.append_query(uri, URI.encode_query(before: article_token)),
        else: uri

    response = Reddit.Auth.get!(identity, uri)

    defsection :ignored, "Inspect Article fields" do
      Logger.debug(
        "Article fields: " <>
          (Enum.flat_map(response.body["data"]["children"], &Map.keys(&1["data"]))
           |> Enum.uniq()
           |> Enum.join(", "))
      )
    end

    articles =
      response.body["data"]["children"]
      |> Enum.map(& &1["data"])
      |> Enum.map(fn post ->
        %Post{
          id: "#{@article_kind}#{post["id"]}",
          username: post["author"],
          parent: post["parent_id"],
          heading: post["title"],
          body: post["selftext"],
          timestamp: post["created"] |> trunc() |> DateTime.from_unix!()
        }
      end)

    article_token =
      articles
      |> Enum.max_by(& &1.timestamp, fn -> %{} end)
      |> Map.get(:id, article_token)

    {articles, article_token}
  end
end
