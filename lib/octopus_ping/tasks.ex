defmodule OctopusPing.Tasks do
  require Logger

  def ping(target, :ip) do
    ping_host(target)
  end

  def ping(target, :url) do
    curl_site(target)
  end

  defp ping_host(host) do
    command =
      case :os.type() do
        {:unix, :linux} ->
          ["ping", [host, "-c 1", "-w 2"]]

        {:win32, :nt} ->
          ["ping", [host]]

        _ -> # MacOS et al
          ["ping", [host]]
      end

    case System.cmd(hd(command), Enum.at(command, 1)) do
      {_, 0} ->
        Logger.info("pinging #{host}")
        {:ok, :alive}
      error ->
        Logger.error("could not ping #{host} due to error: \n#{inspect(error)}")
        {:error, :host_unresponsive}
    end
  end

  defp curl_site(site) do
    args = ["-s", "-o", "/dev/null", "-w", "%{http_code}", site]

    case System.cmd("curl", args) do
      {response_code, _} when response_code in ["200", "301", "302"] ->
        Logger.info("curl request to #{site} succeeded with code #{response_code}")
        {:ok, :up}

      {response_code, _} ->
        Logger.error("curl request to #{site} failed with status code #{response_code}.")
        {:error, :down}
    end
  end
end
