defmodule Reddit.Auth do
  @moduledoc """
  Abstraction over the particulars of how to authenticate with Reddit

  Takes care of refreshing its own access token behind the scenes.
  """
  require Logger
  use Util.Sections

  @opaque t :: %__MODULE__{
            identity: String.t(),
            client: OAuth2.Client.t()
          }
  @enforce_keys [:identity]
  defstruct [:identity, :client]

  use GenServer

  @platform :os.type() |> Tuple.to_list() |> Enum.at(1) |> Atom.to_string()
  @version Mix.Project.config()[:version]
  @useragent {"User-Agent", "#{@platform}:inara_bot_ex:#{@version} (by /u/wldmr)"}

  # For some reason Reddit only accepts form-encoded and replies with json. Seems inconsistent, but oh well …
  @content_type {"Content-Type", "application/x-www-form-urlencoded"}
  @accept {"Accept", "application/json"}

  ## Client API
  @spec get!(atom(), URI.t()) :: OAuth2.Response.t() | OAuth2.Error.t()
  def get!(identity, %URI{} = uri) do
    auth = GenServer.call(via(identity), :get)
    uri = URI.to_string(uri)

    defsection :timed, "Executing get on #{uri} for #{auth.identity}" do
      OAuth2.Client.get!(auth.client, uri)
    end
  end

  @spec post!(atom(), URI.t()) :: OAuth2.Response.t() | OAuth2.Error.t()
  def post!(identity, %URI{} = uri, body \\ %{}) do
    auth = GenServer.call(via(identity), :get)
    uri = URI.to_string(uri)

    defsection :timed, "Executing post on #{uri} for #{auth.identity}" do
      OAuth2.Client.post!(auth.client, uri, body)
    end
  end

  @spec new_client(atom()) :: OAuth2.Client.t()
  defp new_client(identity) do
    prefix = [:reddit, identity]
    username = Environment.get_value!(:username, prefix: prefix)
    password = Environment.get_value!(:password, prefix: prefix)
    client_id = Environment.get_value!(:client_id, prefix: prefix)
    client_secret = Environment.get_value!(:client_secret, prefix: prefix)

    OAuth2.Client.new(
      strategy: OAuth2.Strategy.Password,
      client_id: client_id,
      client_secret: client_secret,
      params: %{"username" => username, "password" => password},
      site: "https://oauth.reddit.com",
      token_url: "https://#{client_id}:#{client_secret}@www.reddit.com/api/v1/access_token"
    )
    |> OAuth2.Client.put_serializer("application/json", Jason)
  end

  defp via(identity) do
    # not a via tuple (despite the name), but can be easily made into one if using a registry.
    # For the time being an atom is less hassle and easier to read in :observer
    String.to_atom("#{__MODULE__}.#{identity}")
  end

  # @spec start_link(atom()) :: GenServer.on_start()
  def start_link(identity) do
    GenServer.start_link(__MODULE__, identity, name: via(identity))
  end

  def stop(identity, reason \\ :normal, timeout \\ :infinity),
    do: GenServer.stop(via(identity), reason, timeout)

  @impl GenServer
  @spec init(atom()) :: {:ok, %__MODULE__{}, {:continue, :refresh_token}}
  def init(identity),
    do: {:ok, %__MODULE__{identity: identity, client: nil}, {:continue, :refresh_token}}

  @impl GenServer
  def handle_call(:get, _from, auth), do: {:reply, auth, auth}

  @impl GenServer
  def handle_continue(:refresh_token, auth) do
    Logger.debug("Existing client: #{inspect(auth.client)}")

    authorized_client =
      defsection :timed, "Getting new token for identity #{inspect(auth.identity)}." do
        new_client(auth.identity)
        |> OAuth2.Client.put_headers([@useragent])
        |> OAuth2.Client.get_token!()
      end

    # `get_token!` doesn't preserve headers. We re-add them right away,
    # so that functions using the client don't have to anymore.
    authorized_client =
      OAuth2.Client.put_headers(authorized_client, [@useragent, @content_type, @accept])

    Logger.debug("Refreshed client: #{inspect(authorized_client)}")

    DateTime.from_unix!(authorized_client.token.expires_at)
    |> DateTime.add(-10, :second)
    |> schedule_token_refresh()

    new_auth = %{auth | client: authorized_client}

    {:noreply, new_auth}
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
