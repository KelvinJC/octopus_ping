defmodule OctopusPing do
  @moduledoc """
  Documentation for `OctopusPing`.
  """

  def start(category, addresses) when is_list(addresses) do
    IO.puts("Start pinging all IPs in #{inspect(addresses)}.")
    start_worker(
      %{
        category: category,
        addresses: addresses
      }
    )
  end

  def start(_) do
    IO.puts("Error. Invalid argument value for addresses.")
  end

  def stop(name) do
    via_tuple(name)
    |> GenServer.cast(:stop_tasks)

    IO.puts("Stop monitoring #{name}.")
  end

  def restart(name) do
    via_tuple(name)
    |> GenServer.cast(:restart_tasks)
  end

  def get_live(name) do
    via_tuple(name)
    |> GenServer.call(:get_successful)
  end

  def get_dead(name) do # or get_unreachable(name)
    via_tuple(name)
    |> GenServer.call(:get_failed)
  end

  defp start_worker(resource) do
    DynamicSupervisor.start_child(
      OctopusPing.PingSupervisor,
      {OctopusPing.NetManager, resource}
    )
  end

  defp via_tuple(name), do: {:via, Registry, {OctopusPing.Registry, name}}
end
