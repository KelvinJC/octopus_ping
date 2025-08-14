defmodule OctopusPing do
  @moduledoc """
  Documentation for `OctopusPing`.
  """
  require Logger
  alias OctopusPing.NameGen

  def start(addresses) when is_list(addresses) do
    name = NameGen.generate()
    resource = %{
      name: name,
      category: :ip,
      addresses: addresses
    }
    start_manager(resource)
    Logger.info("Start pinging all IPs in #{inspect(addresses)}.")
    name
  end

  def start(_) do
    Logger.error("Error. Invalid argument value. start/1 expects a list of IP addresses.")
    {:error, :invalid_arg}
  end

  def start(addresses, :url) when is_list(addresses) do
    name = NameGen.generate()
    resource = %{
      name: name,
      category: :url,
      addresses: addresses
    }
    start_manager(resource)
    Logger.info("Start curl requests to all URLs in #{inspect(addresses)}.")
    name
  end

  def start(_, _) do
    Logger.error("Error. Invalid argument values. start/2 expects a list of IP addresses and :url")
    {:error, :invalid_arg}
  end

  def stop(name) do
    via_tuple(name)
    |> GenServer.cast(:stop_tasks)

    Logger.info("Stop monitoring #{name}.")
  end

  def restart(name) do
    via_tuple(name)
    |> GenServer.cast(:restart_tasks)
    Logger.info("Restart monitoring #{name}.")
  end

  def get_live(name) do
    via_tuple(name)
    |> GenServer.call(:get_successful)
  end

  def get_dead(name) do # or get_unreachable(name)
    via_tuple(name)
    |> GenServer.call(:get_failed)
  end

  defp start_manager(resource) do
    DynamicSupervisor.start_child(
      OctopusPing.PingSupervisor,
      {OctopusPing.NetManager, resource}
    )
  end

  defp via_tuple(name), do: {:via, Registry, {OctopusPing.Registry, name}}
end
