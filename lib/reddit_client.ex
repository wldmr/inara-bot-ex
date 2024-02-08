defmodule Reddit.Client do
  require Logger
  use Util.Sections
  alias OAuth2.Client

  use GenServer

  @singleton_process __MODULE__
  @version Mix.Project.config()[:version]
  @useragent {"User-Agent", "inara_bot_ex (version #{@version}) by /u/wldmr"}

  ## Client API
  @spec get!(URI.t()) :: OAuth2.Response.t() | OAuth2.Error.t()
  def get!(%URI{} = uri) do
    client = GenServer.call(@singleton_process, :get)
    uri = URI.to_string(uri)

    defsection :timed, "Executing get on #{uri}" do
      result = client |> Client.get!(uri)
    end

    result
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
      params: %{"username" => username, "password" => password},
      site: "https://oauth.reddit.com",
      token_url: "https://#{client_id}:#{client_secret}@www.reddit.com/api/v1/access_token"
    )
    |> Client.put_serializer("application/json", Jason)
  end

  ## GenServer callbacks
  def start_link(opt \\ []),
    do: GenServer.start_link(__MODULE__, nil, Keyword.merge(opt, name: @singleton_process))

  def stop(reason \\ :normal, timeout \\ :infinity),
    do: @singleton_process |> GenServer.stop(reason, timeout)

  @impl GenServer
  @spec init(any()) :: {:ok, nil, {:continue, :refresh_token}}
  def init(_init_arg), do: {:ok, nil, {:continue, :refresh_token}}

  @impl GenServer
  def handle_call(:get, _from, client), do: {:reply, client, client}

  @impl GenServer
  def handle_continue(:refresh_token, _state) do
    defsection :timed, "Getting new token." do
      authorized_client = new_client() |> Client.put_headers([@useragent]) |> Client.get_token!()
    end

    # Client functions don't preserve headers, so we re-add them,
    # so that functions using the client don't have to.
    authorized_client = authorized_client |> Client.put_headers([@useragent])

    DateTime.from_unix!(authorized_client.token.expires_at)
    |> DateTime.add(-10, :second)
    |> schedule_token_refresh()

    {:noreply, authorized_client}
  end

  @impl GenServer
  def handle_info(:refresh_token, state), do: {:noreply, state, {:continue, :refresh_token}}

  @spec schedule_token_refresh(DateTime.t()) :: reference()
  defp schedule_token_refresh(%DateTime{} = next_refresh) do
    interval_ms = DateTime.diff(next_refresh, DateTime.utc_now(), :millisecond) |> max(0)

    Logger.info(
      "Scheduling Token refresh for #{next_refresh} (in #{interval_ms / 3_600_000} hours)."
    )

    Process.send_after(self(), :refresh_token, interval_ms)
  end
end
