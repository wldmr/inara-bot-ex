defmodule Reddit do
  alias Jason.Encoder.Integer
  require Logger
  use Util.Sections

  @opaque latest_token() :: %{comment: Post.id(), article: Post.id()}

  @comment_kind "t1"
  @article_kind "t3"

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

  defguardp is_reply(post) when not is_nil(post.parent)

  @spec send_post(atom(), Post.t()) :: Post.id()
  def send_post(identity, %Post{} = post) when is_reply(post) do
    Logger.debug("Replying to #{post.parent} as #{identity} with #{post.body}")

    uri = URI.new!("/api/comment")

    content = %{
      api_type: "json",
      thing_id: post.parent,
      text: post.body
    }

    response = Reddit.Auth.post!(identity, uri, content)

    defsection :ignored, "Inspect Post response fields" do
      Logger.debug(
        "Post response fields: " <>
          (Enum.flat_map(response.body["json"]["data"]["things"], &Map.keys(&1["data"]))
           |> Enum.uniq()
           |> Enum.join(", "))
      )
    end

    # We expect the response to contain a list of length 1, containing a data object with an id.
    # It's pretty convoluted, I know.
    [%{"data" => %{"id" => id}}] = response.body["json"]["data"]["things"]
    comment_fullname = @comment_kind <> "_" <> id
    Logger.debug("Reply to #{post.parent} has been assigned the ID #{comment_fullname}")
    comment_fullname
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

    comments = to_posts(response.body)

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

    articles = to_posts(response.body)

    article_token =
      articles
      |> Enum.max_by(& &1.timestamp, fn -> %{} end)
      |> Map.get(:id, article_token)

    {articles, article_token}
  end

  defp to_posts(%{"data" => %{"children" => items}}) do
    Enum.map(items, &to_post/1)
  end

  defp to_post(%{"kind" => @comment_kind, "data" => comment}) do
    %Post{
      id: "#{@comment_kind}_#{comment["id"]}",
      username: comment["author"],
      parent: comment["parent_id"],
      heading: nil,
      body: comment["body"],
      timestamp: comment["created"] |> trunc() |> DateTime.from_unix!()
    }
  end

  defp to_post(%{"kind" => @article_kind, "data" => article}) do
    %Post{
      id: "#{@article_kind}_#{article["id"]}",
      username: article["author"],
      parent: nil,
      heading: article["title"],
      body: article["selftext"],
      timestamp: article["created"] |> trunc() |> DateTime.from_unix!()
    }
  end
end
