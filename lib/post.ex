defmodule Post do
  @moduledoc """
  A post that some user made somewhere. Bots also produce posts.

  Posts form a logical tree; the `parent` field signifies which post this one is a response to (if any).

  There is no separate representation for a 'topic', 'thread' or the like. A post _should_ point to its parent
  if it isn't the first post in a topic. It is completely up to each implementation whether a linear conversation
  (say, in a classical forum) is represented as all replying to the first post, or as replying to each other
  in sequence. Bot code should not make any assumptions about this.

  A heading alone may or may not be the thread title; it's not impossible that some forums allow
  replies with individual titles (e.g. email lists). If the post has a `heading` and has no `parent`,
  it _might_ be the thread title, but … well, who knows.
  """
  defstruct [:id, :username, :parent, :heading, :body, :timestamp]

  @type t :: %__MODULE__{
          id: id(),
          username: String.t(),
          parent: id(),
          heading: String.t(),
          body: String.t(),
          timestamp: DateTime.t()
        }

  @typedoc "Some data by which to uniquely identify a post."
  @opaque id :: binary()

end
