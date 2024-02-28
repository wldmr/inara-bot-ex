defmodule Infra.Environment do
  @doc """

  ## Examples

  Get a value with a prefix in the name:

    iex> System.put_env("INARA_BOT_TEST_ID_SOME_PROP", "It worked!")
    iex> get_value!(:some_prop, prefix: :test_id)
    "It worked!"

  Values can be converted by giving an conversion function:

    iex> System.put_env("INARA_BOT_NUMERICAL", "15.4")
    iex> get_value!(:numerical, convert: &String.to_float/1)
    15.4
  """
  def get_value!(property_name, opts \\ []) when is_atom(property_name) do
    prefix =
      Enum.find_value(opts, "", fn
        {:prefix, value} -> "_" <> Atom.to_string(value)
        _ -> nil
      end)

    convert =
      Enum.find_value(opts, &Function.identity/1, fn
        {:convert, func} -> func
        _ -> nil
      end)

    prop = "_" <> Atom.to_string(property_name)

    "INARA_BOT#{prefix}#{prop}"
    |> String.upcase()
    |> System.fetch_env!()
    |> convert.()
  end
end
