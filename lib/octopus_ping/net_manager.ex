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
    # Send a message to our self that we should start the tasks at once!
    Process.send(self(), :start_tasks, [])
    {:ok, %{network_resource: network_resource, tasks: MapSet.new()}}
  end

  def handle_cast({:task, url}, %{network_resource: %{category: "Apps"}} = state) do
    task =
      Task.Supervisor.async_nolink(
        OctopusPing.TaskSupervisor, # reference the task supervisor by name
        fn -> Tasks.curl_site(url) end
      )

    # Register the task in the GenServer state, so that we can track which
    # tasks responded with a successful curl request, and which didn't.
    {:noreply, %{state | tasks: MapSet.put(state.tasks, %{url: url, status: :pending, task: task})}}
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

  def handle_info(:start_tasks, state) do
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

  # the ping request succeeds
  def handle_info({_ref, {:ok, _msg}}, state) do
    {:noreply, state}
  end

  # the ping request fails
  def handle_info({_ref, {:error, _msg}}, state) do
    {:noreply, state}
  end

  # the task itself failed
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:noreply, state}
  end

  defp via_tuple(name), do: {:via, Registry, {OctopusPing.Registry, name}}
end
