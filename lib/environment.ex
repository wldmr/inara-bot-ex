defmodule Environment do
  defmacrop raise_if_nil(value, msg) do
    quote do
      case unquote(value) do
        nil -> raise unquote(msg)
        nonnil -> nonnil
      end
    end
  end

  defmacrop if_exists(value, func) do
    quote do
      case unquote(value) do
        nil -> nil
        nonnil -> unquote(func).(nonnil)
      end
    end
  end

  @doc """

  ## Examples

  Get a value with a prefix in the name (anything convertible to string):

      iex> System.put_env("INARA_BOT_TEST_ID_SOME_PROP", "It worked!")
      iex> get_value!(:some_prop, prefix: :test_id)
      "It worked!"
      iex> get_value!(:some_prop, prefix: "test_id")
      "It worked!"

  The prefix can also be a list of things:

      iex> System.put_env("INARA_BOT_TEST_ID_SOME_PROP", "It worked!")
      iex> get_value!(:some_prop, prefix: [:test, "id"])
      "It worked!"

  The prefix can also be nil or the empty list:

      iex> System.put_env("INARA_BOT_SOME_PROP", "It worked!")
      iex> get_value!(:some_prop, prefix: [])
      "It worked!"
      iex> get_value!(:some_prop, prefix: nil)
      "It worked!"

  Values can be converted by giving a conversion function:

      iex> System.put_env("INARA_BOT_NUMERICAL", "15.4")
      iex> get_value!(:numerical, convert: &String.to_float/1)
      15.4

  You can give a default value:

      iex> get_value!(:doesnt_exist, default: "phew!")
      "phew!"

  Otherwise, raise an error:

      iex> get_value!(:doesnt_exist)
      ** (RuntimeError) No environemnt variable named INARA_BOT_DOESNT_EXIST, and no default given.

  """
  def get_value!(property_name, opts \\ []) when is_atom(property_name) do
    prefix = Keyword.get(opts, :prefix)

    prefix =
      case prefix do
        nil -> ""
        [] -> ""
        values when is_list(values) -> "_" <> Enum.map_join(values, "_", &"#{&1}")
        value -> "_#{value}"
      end

    convert = Keyword.get(opts, :convert, &Function.identity/1)
    default = if_exists(Keyword.get(opts, :default), &String.Chars.to_string/1)

    env_name = String.upcase("INARA_BOT#{prefix}_#{property_name}")

    env_name
    |> System.get_env(default)
    |> raise_if_nil("No environemnt variable named #{env_name}, and no default given.")
    |> convert.()
  end
end
