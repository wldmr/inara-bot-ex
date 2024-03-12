defmodule Environment do
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

  Values can be converted by giving a conversion function:

      iex> System.put_env("INARA_BOT_NUMERICAL", "15.4")
      iex> get_value!(:numerical, convert: &String.to_float/1)
      15.4
  """
  def get_value!(property_name, opts \\ []) when is_atom(property_name) do
    prefix =
      Enum.find_value(opts, "", fn
        {:prefix, values} when is_list(values) and length(values) > 0 ->
          "_" <> Enum.map_join(values, "_", &"#{&1}")

        {:prefix, value} ->
          "_#{value}"

        _ ->
          nil
      end)

    convert =
      Enum.find_value(opts, &Function.identity/1, fn
        {:convert, func} -> func
        _ -> nil
      end)

    "INARA_BOT#{prefix}_#{property_name}"
    |> String.upcase()
    |> System.fetch_env!()
    |> convert.()
  end
end
