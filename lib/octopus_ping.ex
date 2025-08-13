defmodule OctopusPing do
  @moduledoc """
  Documentation for `OctopusPing`.
  """

  def start(addresses, :ip) when is_list(addresses) do
    IO.puts("Start pinging all IPs in #{inspect(addresses)}.")
    start_worker(
      %{
        addresses: [
          "192.168.1.0/24",
          "172.24.208.5",
          "8.8.8.8",
          "172.20.112.1",
          "172.24.5.87",
          "172.20.10.4",
          "127.0.0.1"
        ],
        category: "IPs"
      }
    )
  end

  def start(urls, :app) when is_list(urls) do
    IO.puts("Start curl requests to all site urls in #{inspect(urls)}.")
    start_worker(
      %{
        addresses: [
          "https://bbc.com",
          "https://cnn.com",
          "https://netflix.com"
        ],
        category: "Apps"
      }
    )
  end

  def start(_addresses) do
    IO.puts("Error. Invalid value for addresses.")
  end

  def stop(name) do
    via_tuple(name)
    |> GenServer.cast(:stop)

    IO.puts("Stop monitoring #{name}.")
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
