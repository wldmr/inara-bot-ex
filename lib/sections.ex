defmodule Util.Sections do
  defmacro __using__(_opts) do
    quote do
      require Logger
      import unquote(__MODULE__)
    end
  end

  defmacro defsection(timed: name, do: block) do
    quote do
      Logger.debug("Start: " <> unquote(name))
      start_time = DateTime.utc_now()
      unquote(block)
      end_time = DateTime.utc_now()
      duration = DateTime.diff(end_time, start_time, :millisecond)
      Logger.debug("Done: " <> unquote(name) <> " – Took #{duration} milliseconds.")
    end
  end

  defmacro defsection(ignored: _reason, do: _block) do
  end

  defmacro defsection(_name, do: block) do
    quote do
      unquote(block)
    end
  end
end
