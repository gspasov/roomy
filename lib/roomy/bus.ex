defmodule Roomy.Bus do
  @moduledoc """
  TBA
  """
  require Logger

  @single_level "+"
  @multi_level "#"
  @topic_level_separator "/"

  # ====================== #
  #          API           #
  # ====================== #

  @spec subscribe(topic :: String.t()) :: :ok | {:error, :already_subscribed}
  def subscribe(topic) do
    pid = self()

    if pid not in get_subscribers(topic) do
      topic
      |> name()
      |> :pg.join(pid)
    else
      {:error, :already_subscribed}
    end
  end

  @spec unsubscribe(topic :: String.t()) :: :ok
  def unsubscribe(topic) do
    topic
    |> name()
    |> :pg.leave(self())
  end

  @spec get_subscribers(topic :: String.t()) :: [pid()]
  def get_subscribers(topic) do
    topic
    |> name()
    |> :pg.get_members()
  end

  @spec publish(topic :: String.t(), message :: any()) :: :ok
  def publish(topic, message) do
    Logger.debug("[#{__MODULE__}] Publishing to [#{topic}] #{inspect(message)}")

    :pg.which_groups()
    |> Enum.filter(fn {_module, subscribe_topic} -> match(subscribe_topic, topic) end)
    |> tap(fn groups_receiving_message ->
      topics = Enum.map(groups_receiving_message, fn {_, topic} -> topic end)
      Logger.debug("[#{__MODULE__}] Sending message to topics: #{inspect(topics)}")
    end)
    |> Enum.flat_map(fn group -> :pg.get_members(group) end)
    |> Enum.each(fn pid -> send(pid, {__MODULE__, message}) end)
  end

  # ====================== #
  #       Internals        #
  # ====================== #

  @spec match(subscribe_topic :: String.t(), publish_topic :: String.t()) :: boolean()
  defp match(subscribe_topic, publish_topic) do
    do_match(
      String.split(subscribe_topic, @topic_level_separator, trim: true),
      String.split(publish_topic, @topic_level_separator, trim: true)
    )
  end

  @spec do_match([String.t()], [String.t()]) :: boolean()
  defp do_match(subscribe_levels, publish_levels)

  defp do_match([@multi_level | _], _) do
    true
  end

  defp do_match([@single_level | levels_1], [_ | levels_2]) do
    do_match(levels_1, levels_2)
  end

  defp do_match([level | levels_1], [level | levels_2]) do
    do_match(levels_1, levels_2)
  end

  defp do_match([], []) do
    true
  end

  defp do_match(_, _) do
    false
  end

  defp name(topic) do
    {__MODULE__, topic}
  end
end
