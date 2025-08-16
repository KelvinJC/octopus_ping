defmodule OctopusPing.NetManager do
  use GenServer

  alias OctopusPing.TaskUtil
  alias OctopusPing.Tasks
  require Logger

  defstruct [:network_resource, :tasks, halt: :false]

  # network_resource is a map with 2 keys
  # `addresses` - a list of ip addresses or a list of web urls
  # `category` - the description of the resource. Currently `IPs` or `Apps`
  def start_link(%{name: name, addresses: addresses, category: _category} = network_resource) when is_list(addresses) do
    GenServer.start_link(__MODULE__, network_resource, name: via_tuple(name))
  end

  def init(network_resource) do
    # Schedule a message to our self
    schedule()
    {:ok, %__MODULE__{network_resource: network_resource, tasks: MapSet.new(), halt: :false}}
  end

  defp schedule() do
    # Send a message that we should start the tasks after the specified period!
    Process.send_after(self(), :start_tasks, 60_000)
  end

  def handle_cast({:task, url}, %{network_resource: %{category: :url}} = state) do
    task =
      Task.Supervisor.async_nolink(
        OctopusPing.TaskSupervisor, # reference the task supervisor by name
        fn -> Tasks.curl_site(url) end
      )

    # Register the task in the GenServer state, so that we can track which
    # tasks responded with a successful curl request, and which didn't.
    updated_tasks = MapSet.put(
      state.tasks,
      %{url: url, status: :pending, task: task}
    )
    {:noreply, %{state | tasks: updated_tasks}}
  end

  def handle_cast({:task, host}, state) do
    task =
      Task.Supervisor.async_nolink(
        OctopusPing.TaskSupervisor, # reference the task supervisor by name
        fn -> Tasks.ping_host(host) end
      )

    # Register the task in the GenServer state, so that we can track which
    # tasks responded with a successful ping request, and which didn't.
    updated_tasks = MapSet.put(
      state.tasks,
      %{host: host, status: :pending, task: task}
    )
    {:noreply, %{state | tasks: updated_tasks}}
  end

  def handle_cast(:stop_tasks, state), do: {:noreply, %{state | halt: :true}}

  def handle_cast(:restart_tasks, state) do
    schedule()
    {:noreply, %{state | halt: :false}}
  end

  def handle_info(:start_tasks, state) do
    if state.halt do
      Logger.info("Tasks have been stopped. \nState: #{inspect(state)}")
    else
      Enum.map(
        state.network_resource.addresses,
        fn host ->
          state.network_resource.name
          |> via_tuple()
          |> GenServer.cast({:task, host})
        end
      )

      schedule()
    end

    {:noreply, %{state | tasks: MapSet.new()}} # start each task round with a new task list
  end

  # the request succeeds
  def handle_info({ref, {:ok, _msg}}, state) do
    updated_tasks = TaskUtil.process_task_response(ref, state, :successful)
    {:noreply, %{state | tasks: updated_tasks}}
  end

  # the request fails
  def handle_info({ref, {:error, _msg}}, state) do
    updated_tasks = TaskUtil.process_task_response(ref, state, :failed)
    {:noreply, %{state | tasks: updated_tasks}}
  end

  # the task itself failed
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:noreply, state}
  end

  def handle_call(:get_successful, _from, state) do
    hosts_or_urls = TaskUtil.filter_by_status(:successful, state.tasks)
    {:reply, hosts_or_urls, state}
  end

  def handle_call(:get_failed, _from, state) do
    hosts_or_urls = TaskUtil.filter_by_status(:failed, state.tasks)
    {:reply, hosts_or_urls, state}
  end

  defp via_tuple(name), do: {:via, Registry, {OctopusPing.Registry, name}}
end
