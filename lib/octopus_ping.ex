defmodule OctopusPing do
  @moduledoc """
  Documentation for `OctopusPing`.
  """

  def start_ping(addresses) do
    IO.puts("Start pinging all IPs in #{addresses}.")
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

  defp start_worker() do
    IO.puts("UI will eventually start new ping jobs")
  end
end
