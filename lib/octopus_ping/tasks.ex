defmodule OctopusPing.Tasks do
  def ping_host(host) do
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
        IO.puts("pinging #{host}")
        {:ok, :alive}
      error ->
        IO.puts("could not ping #{host} due to error: \n#{inspect(error)}\n\n")
        {:error, :host_unresponsive}
    end
  end

  def curl_site(site) do
    args = ["-s", "-o", "/dev/null", "-w", "%{http_code}", site]

    case System.cmd("curl", args) do
      {response_code, _} when response_code in ["200", "301", "302"] ->
        IO.puts("curl request to #{site} succeeded with code #{response_code}")
        {:ok, :up}

      {response_code, _} ->
        IO.puts("curl request to #{site} failed with status code #{response_code}.")
        {:error, :down}
    end
  end
end
