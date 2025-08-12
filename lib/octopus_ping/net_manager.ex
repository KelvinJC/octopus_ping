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
    # Schedule a message to our self
    schedule()
    {:ok, %{network_resource: network_resource, tasks: MapSet.new()}}
  end

  defp schedule() do
    # Send a message that we should start the tasks after the specified period!
    Process.send_after(self(), :start_tasks, 60_000)
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

    schedule()
    {:noreply, state}
  end

  # the ping request succeeds
  def handle_info({ref, {:ok, :alive}}, state) do
    task =
      Enum.find(
        state.tasks,
        fn %{host: _host, status: _status, task: %{ref: r}} ->
          r == ref
        end
      )

    Logger.info("Successfully pinged host #{task.host}")
    # demonitor and flush task.
    Process.demonitor(ref, [:flush])

    updated_tasks =
      state.tasks
      |> MapSet.delete(task)
      |> MapSet.put(%{task | status: :successful})

    {:noreply, %{state | tasks: updated_tasks}}
  end

  # the curl request succeeds
  def handle_info({ref, {:ok, :up}}, state) do
    task =
      Enum.find(
        state.tasks,
        fn %{url: _url, status: _status, task: %{ref: r}} ->
          r == ref
        end
      )

    Logger.info("Successful curl request made to url #{task.url}")

    updated_tasks =
      state.tasks
      |> MapSet.delete(task)
      |> MapSet.put(%{task | status: :successful})

    {:noreply, %{state | tasks: updated_tasks}}
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
