defmodule SlackLoggerBackend.Logger do

  @moduledoc """
  The actual logger backend for sending logger events to Slack.
  """

  use GenEvent
  alias SlackLoggerBackend.Producer

  @env_webhook "SLACK_LOGGER_WEBHOOK_URL"
  @default_log_levels [:error]

  @doc false
  def init(__MODULE__) do
    {:ok, %{levels: []}}
  end

  def init({__MODULE__, levels}) when is_atom(levels) do
    {:ok, %{levels: [levels]}}
  end

  def init({__MODULE__, levels}) when is_list(levels) do
    {:ok, %{levels: levels}}
  end

  @doc false
  def handle_call(_request, state) do
    {:ok, state}
  end

  @doc false
  def handle_event({level, _pid, {_, message, _timestamp, detail}}, %{levels: []} = state) do
    levels = case Application.get_env(SlackLoggerBackend, :levels) do
      nil ->
        @default_log_levels
      levels ->
        levels
    end
    if level in levels do
      handle_event(level, message, detail)
    end
    {:ok, %{state | levels: levels}}
  end

  @doc false
  def handle_event({level, _pid, {_, message, _timestamp, detail}}, %{levels: levels} = state) do
    if level in levels do
      handle_event(level, message, detail)
    end
    {:ok, state}
  end

  @doc false
  def handle_event(:flush, state) do
    {:ok, state}
  end

  @doc false
  def handle_info(_message, state) do
    {:ok, state}
  end

  defp get_url do
    case System.get_env(@env_webhook) do
      nil ->
        Application.get_env(SlackLoggerBackend, :slack)[:url]
      url ->
        url
    end
  end

  defp handle_event(level, message, [pid: _, application: application, module: module, function: function, file: file, line: line]) do
    {level, message, application, module, function, file, line}
    |> send_event
  end

  defp handle_event(level, message, [pid: _, module: module, function: function, file: file, line: line]) do
    {level, message, module, function, file, line}
    |> send_event
  end

  defp handle_event(_, _, _) do
    :noop
  end

  defp send_event(event) do
    Producer.add_event({get_url(), event})
  end

end
