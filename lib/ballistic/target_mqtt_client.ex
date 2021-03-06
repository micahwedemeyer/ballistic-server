defmodule Ballistic.TargetMqttClient do
  require Logger
  alias Hulaaki.Message.Publish
  use Hulaaki.Client

  # Define like this to override/overrule the start_link in Hulaaki.Client
  def start_link({:first}, name) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{}, name: name)
    pid |> connect |> schedule_ping
    {:ok, pid}
  end

  def connect(pid) do
    opts = [
      client_id: "target-mqtt-client",
      host: Application.get_env(:ballistic, :mqtt_host),
      port: Application.get_env(:ballistic, :mqtt_port)
    ]

    # Call Hulaaki.Client.connect
    connect(pid, opts)
    pid
  end

  def request_introductions do
    publish(topic: "darter/all/requestIntroduction", message: "", qos: 0, dup: 0, retain: 0)
  end

  def subscribe_to_hits do
    subscribe(id: 1, topics: ["darter/+/hits"], qoses: [0])
  end

  def subscribe_to_introductions do
    subscribe(id: 1, topics: ["darter/+/introduction"], qoses: [0])
  end

  def play_show(device_id, show_id) do
    message = Poison.encode!(%Ballistic.Messages.PlayShow{showId: show_id})
    publish(topic: "darter/#{device_id}/playShow", message: message, qos: 0, dup: 0, retain: 0)
  end


  # Private'ish API
  def subscribe(options) do
    GenServer.whereis(__MODULE__)
    |> subscribe(options)
  end

  def publish(options) do
    GenServer.whereis(__MODULE__)
    |> publish(options)
  end

  def on_subscribed_publish(message: %Publish{} = message, state: _state) do
    Logger.debug("TargetMqttClient received message on #{message.topic}: #{message.message}")

    topic = message.topic
    hits_regex = ~r/darter\/(.*)\/hits/
    intro_regex = ~r/darter\/(.*)\/introduction/

    cond do
      Regex.match?(hits_regex, topic) ->
        parse_message(:hits, message)
      Regex.match?(intro_regex, topic) ->
        parse_message(:introduction, message)
      true ->
        parse_message(topic, message)
    end |> handle_message
  end

  def parse_message(:hits, message) do
    Poison.decode!(message.message, as: %Ballistic.Messages.Hit{})
  end

  def parse_message(:introduction, message) do
    Poison.decode!(message.message, as: %Ballistic.Messages.Introduction{})
  end

  def parse_message(_topic, _message) do
    Logger.debug("Unrecognized topic")
    nil
  end

  def handle_message(%Ballistic.Messages.Hit{} = hit) do
    Ballistic.Target.whereis(hit.deviceId)
    |> Ballistic.Target.hit(hit.timestamp)
  end

  def handle_message(%Ballistic.Messages.Introduction{} = intro) do
    Ballistic.TargetSupervisor.init_target(intro.deviceId)
  end

  def handle_message(_message), do: :ok


  defp schedule_ping(pid) do
    Process.send_after(pid, :ping_server, 30 * 1000)
    pid
  end

  def handle_info(:ping_server, state) do
    self
    |> schedule_ping
    |> GenServer.cast(:ping)
    {:noreply, state}
  end

  # Allow us to do it as a cast, not a call
  def handle_cast(:ping, state) do
    :ok = state.connection |> Connection.ping
    {:noreply, state}
  end
end