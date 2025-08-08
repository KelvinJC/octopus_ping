defmodule OctopusPing.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: OctopusPing.PingSupervisor},
      {Registry, keys: :unique, name: OctopusPing.Registry},
      {Task.Supervisor, name: OctopusPing.TaskSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OctopusPing.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
