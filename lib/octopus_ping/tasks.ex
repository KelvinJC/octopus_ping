defmodule OctopusPing.Tasks do
  def ping_host(host) do
    case System.cmd("ping", [host, "-c 1", "-w 2"]) do
    # case System.cmd("ping", [host, "-w 2"]) do  # {"Access denied. Option -c 1 requires administrative privileges.\r\n", 1}
      {_, 0} ->
        IO.puts("pinging #{host}")
        {:ok, :alive}
      error ->
        IO.puts("could not ping #{host} due to error: \n#{inspect(error)}\n\n")
        {:error, :host_unresponsive}
    end
  end
end
