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
    {:noreply, %{state | tasks: MapSet.new()}} # start each task round with a new task list
  end

  # the request succeeds
  def handle_info({ref, {:ok, _msg}}, state) do
    updated_tasks = process_task(ref, state, :successful)

    {:noreply, %{state | tasks: updated_tasks}}
  end

  # the request fails
  def handle_info({ref, {:error, _msg}}, state) do
    updated_tasks = process_task(ref, state, :failed)

    {:noreply, %{state | tasks: updated_tasks}}
  end

  # the task itself failed
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:noreply, state}
  end

  def handle_call(:get_successful, _from, state) do
    tasks =
      Enum.filter(
        state.tasks,
        fn %{status: status} ->
          status == :successful
        end
      )

    hosts_or_urls =
      for task <- tasks do
        case state.network_resource.category do
          "IPs" ->
            task.host
          "Apps" ->
            task.url
        end
      end

    {:reply, hosts_or_urls, state}
  end

  defp process_task(task_reference, state, task_status) do
    # demonitor and flush task process.
    Process.demonitor(task_reference, [:flush])

    # query task info from state
    task =
      Enum.find(
        state.tasks,
        fn %{task: %{ref: ref_id}}  ->
          ref_id == task_reference
        end
      )

    # update task info in state
    case task do
      nil ->
        state.tasks

      _task_found ->
        state.tasks
        |> MapSet.delete(task)
        |> MapSet.put(%{task | status: task_status})
    end
  end

  defp via_tuple(name), do: {:via, Registry, {OctopusPing.Registry, name}}
end
