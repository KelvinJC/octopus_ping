defmodule OctopusPing.TaskUtil do
  def process_task_response(task_reference, state, task_status) do
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

  @doc """
  Extracts the hosts or URLs of tasks matching the given status.

  ## Parameters
    * `task_status` — the task status to match (e.g., `:successful`, `:failed`).
    * `tasks` — the list of task maps stored in state. Each containing a `:status` key
      and a `:host` or `:url` key

  ## Returns
  A list of hosts or URLs for all tasks whose status matches `task_status`.

  ## Examples

      iex> tasks = [
      ...>   %{
      ...>      host: "192.168.0.1",
      ...>      status: :pending
      ...>    },
      ...>   %{
      ...>      host: "127.0.0.1",
      ...>      status: :successful
      ...>    },
      ...>   %{
      ...>      host: "8.8.8.8",
      ...>      status: :failed
      ...>    }
      ...> ]
      iex> OctopusPing.NetManager.filter_by_status(:failed, tasks)
      ["8.8.8.8"]
  """
  def filter_targets_by_status(task_status, tasks) do
    Enum.flat_map(
      tasks,
      fn %{status: status} = task ->
        if status == task_status do
          targets = Map.get(task, :target)
          [targets]
        else
          []
        end
      end
    )
  end
end
