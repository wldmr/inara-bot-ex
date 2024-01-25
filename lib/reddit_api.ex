defmodule RedditApi do
  alias OAuth2.Client

  use GenServer

  @singleton_process __MODULE__
  @version Mix.Project.config()[:version]
  @useragent {"User-Agent", "inara_bot_ex (version #{@version}) by /u/wldmr"}

  defmacrop report_duration(message, do: block) do
    quote do
      IO.puts("Start: " <> unquote(message))
      start_time = DateTime.utc_now()
      unquote(block)
      end_time = DateTime.utc_now()
      duration = DateTime.diff(end_time, start_time, :millisecond)
      IO.puts("Done: " <> unquote(message) <> " – Took #{duration} milliseconds.")
    end
  end

  defp new_client(
         username \\ "wldmr",
         password \\ "o^!#[L5'O%h-VS|",
         client_id \\ "-AH5MGx3XUR9e0Jw_ILpoQ",
         client_secret \\ "ELjaKlcDIigYxSdYVpPqRfoDswlbaw"
       ) do
    OAuth2.Client.new(
      strategy: OAuth2.Strategy.Password,
      client_id: client_id,
      client_secret: client_secret,
      params: %{
        "username" => username,
        "password" => password
      },
      site: "https://oauth.reddit.com",
      token_url: "https://#{client_id}:#{client_secret}@www.reddit.com/api/v1/access_token"
    )
    |> Client.put_serializer("application/json", Jason)
    |> Client.put_headers([@useragent])
  end

  @spec get!(Client.t(), String.t(), Keyword.t()) :: term()
  defp get!(client, url, opts \\ []) do
    client_with_params = Enum.reduce(opts, client, fn {k, v}, c -> Client.put_param(c, k, v) end)
    client_with_params |> Client.get!(url, [@useragent])
  end

  def start_link(opt \\ []),
    do: GenServer.start_link(__MODULE__, nil, Keyword.merge(opt, name: @singleton_process))

  def latest_comments(opts \\ []),
    do: @singleton_process |> GenServer.call({:latest_comments, opts})

  def stop(reason \\ :normal, timeout \\ :infinity),
    do: @singleton_process |> GenServer.stop(reason, timeout)

  @impl GenServer
  @spec init(any()) :: {:ok, nil, {:continue, :refresh_token}}
  def init(_init_arg), do: {:ok, nil, {:continue, :refresh_token}}

  @impl GenServer
  def handle_call({:latest_comments, opts}, _from, state) do
    uri = URI.new!("/r/firefly/comments")

    uri =
      Enum.reduce(opts, uri, fn {k, v}, acc -> URI.append_query(acc, "#{k}=#{v}") end)
      |> URI.to_string()

    response = get!(state, uri)

    comments =
      response.body["data"]["children"]
      |> Enum.map(&Map.get(&1, "data"))
      |> Enum.map(&Map.take(&1, ["author", "id", "body", "replies"]))

    {:reply, comments, state}
  end

  @impl GenServer
  def handle_continue(:refresh_token, _state) do
    report_duration "Getting new token." do
      authorized_client = new_client() |> Client.get_token!()
    end

    DateTime.from_unix!(authorized_client.token.expires_at)
    |> DateTime.add(-10, :second)
    |> schedule_token_refresh()

    {:noreply, authorized_client}
  end

  @impl GenServer
  def handle_info(:refresh_token, state) do
    {:noreply, state, {:continue, :refresh_token}}
  end

  @spec schedule_token_refresh(DateTime.t()) :: reference()
  defp schedule_token_refresh(%DateTime{} = next_refresh) do
    interval_ms = DateTime.diff(next_refresh, DateTime.utc_now(), :millisecond) |> max(0)
    IO.puts("Scheduling Token refresh for #{next_refresh} (in #{interval_ms / 3_600_000} hours).")
    Process.send_after(self(), :refresh_token, interval_ms)
  end
end
