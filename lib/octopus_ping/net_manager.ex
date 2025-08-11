defmodule OctopusPing.NetManager do
  use GenServer

  alias OctopusPing.Tasks
  require Logger

  # network_resource is a map with 2 keys
  # `addresses` - a list of ip addresses or a list of web urls
  # `category` - the description of the resource. Currently `IPs` or `Applications`
  def start_link(%{addresses: addresses, category: category} = network_resource) when is_list(addresses) do
    GenServer.start_link(__MODULE__, network_resource, name: via_tuple(category))
  end

  def init(network_resource) do
    # Send a message to our self that we should start pinging at once!
    Process.send(self(), :start_ping, [])
    {:ok, %{network_resource: network_resource, tasks: MapSet.new()}}
  end

  def handle_cast({:task, host}, state) do
    task =
      Task.Supervisor.async_nolink(
        OctopusPing.TaskSupervisor, # reference the task supervisor by name
        fn -> Tasks.ping_host(host) end
      )

    # Register the task in the GenServer state, so that we can track which
    # tasks responded with a successful ping request, and which didn't.
    {:noreply, %{state | tasks: MapSet.put(state.tasks, %{host: host, status: :pending, task: task})}}
  end

  def handle_info(:start_ping, state) do
    Enum.map(
      state.network_resource.addresses,
      fn host ->
        state.network_resource.category
        |> via_tuple()
        |> GenServer.cast({:task, host})
      end
    )

    {:noreply, state}
  end

  defp via_tuple(name), do: {:via, Registry, {OctopusPing.Registry, name}}
end
