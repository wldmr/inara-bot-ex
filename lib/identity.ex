defmodule Identity do
  @moduledoc """
  Abstraction over configuration values tied to an identity.

  An "identity" corresponds to a specific user at a specific site
  (e.g. "/u/johndoe on Reddit", "@johndoe on Mastodon", etc).

  A bit flimsy and overly general at the moment, since it's not entirely clear
  what common properties all identities should have yet and idiosyncracies of
  different sites should be handled (only reddit supported at the moment).
  But the idea is that we don't want to care where an identity property comes from
  (potentially cached, or from a swappable backend).
  """

  @typedoc "uniqely identifies this identity in the system"
  @type t :: atom()
  @type property_t :: any()

  @doc """
  Get a property value for an identity.

  Can be converted to any value and/or type with the function given in the `:convert` option.
  """
  @spec get!(t(), atom()) :: String.t()
  @spec get!(t(), atom(), convert: (String.t() -> property_t())) :: property_t()

  def get!(identity, property, opts \\ []) do
    # we handle the `:default` identity differently, so that the env variable names
    # don't all contain "DEFAULT", which is just ugly.
    prefix = if identity === :default, do: nil, else: identity
    Environment.get_value!(property, Keyword.merge(opts, prefix: prefix))
  end

  @doc "Every identity should at least provide a username."
  @spec username!(t()) :: String.t()
  def username!(identity),
    do: get!(identity, :username)

  @spec site(t()) :: Site.impl()
  def site(identity),
    do:
      get!(identity, :site, default: Site.Reddit)
      |> String.to_existing_atom()
end
