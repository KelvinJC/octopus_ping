defmodule OctopusPing do
  @moduledoc """
  Documentation for `OctopusPing`.
  """

  def start_ping(addresses) when is_list(addresses) do
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

  def start_ping(_addresses) do
    IO.puts("Error. Invalid value for addresses.")
  end

  def stop_ping(addresses) do
    IO.puts("Stop pinging all IPs in #{addresses}.")
  end

  def get_successful_hosts() do
    IO.puts("I will report successful hosts")
  end

  def get_failed_hosts() do
    IO.puts("I will report failed hosts")
  end

  defp start_worker(resource) do
    DynamicSupervisor.start_child(
      OctopusPing.PingSupervisor,
      {OctopusPing.NetManager, resource}
    )
  end
end
