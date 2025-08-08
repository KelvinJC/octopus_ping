defmodule OctopusPing.NetManager do
  use GenServer

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
    {:ok, %{network_resource: network_resource.category, tasks: MapSet.new()}}
  end

  defp via_tuple(name), do: {:via, Registry, {OctopusPing.Registry, name}}
end
