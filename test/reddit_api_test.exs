client = OAuth2.Client.new([
  strategy: OAuth2.Strategy.AuthCode,
  client_id: "-AH5MGx3XUR9e0Jw_ILpoQ",
  client_secret: "ELjaKlcDIigYxSdYVpPqRfoDswlbaw",
  site: "https://www.reddit.com/",
  authorize_url: "api/v1/authorize",
  token_url: "api/v1/access_token",
  redirect_uri: "http://localhost"
])

# Request a token from with the newly created client
# Token will be stored inside the `%OAuth2.Client{}` struct (client.token)
auth_url = OAuth2.Client.authorize_url!(client)
IO.puts auth_url
client = OAuth2.Client.get_token!(client, code: "secret")

# client.token contains the `%OAuth2.AccessToken{}` struct

# raw access token
#access_token = client.token.access_token
