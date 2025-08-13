# OctopusPing

**A concurrent network monitor.**

OctopusPing is a lightweight Elixir application for monitoring the health of network resources in real time.  
It supports concurrent checks of **IP addresses** and **application endpoints (URLs)**, providing instant feedback on availability  
via periodic ping and HTTP requests. Designed for scalability, it can handle multiple targets simultaneously  
while remaining easy to extend and integrate into existing infrastructure.

### How It Works

OctopusPing treats monitored resources as one of two categories:

1. **IPs** — Checked via ICMP ping to determine if the host is reachable.
2. **Apps (URLs)** — Checked via HTTP(S) requests to confirm the endpoint responds successfully.

A dedicated GenServer manages each resource and periodically spawns lightweight tasks to perform the checks.  
Results are stored in memory for quick retrieval and can be filtered by status (e.g., `:successful`, `:failed`, `:pending`).

The system is built to handle:
- High concurrency with minimal resource usage.
- Continuous monitoring without blocking.
- Clear, filterable reporting on monitored resources.

### Prerequisite
If you would like to run the application for yourself, you need to install Elixir on your computer. Elixir can be installed in many ways, but the easiest way is probably to consult the official [documentation](https://elixir-lang.org/install.html) on how to install Elixir for your platform. This will allow you to be able to run 'mix', 'iex' and other Elixir-related commands.

### Getting Started
*To run the app in an iex shell, open a terminal and enter the command*

```iex

  iex - S mix

```

*Give it a spin with the following examples*

- To monitor a bunch of network devices, provide a list of their IP addresses
```iex

  iex> OctopusPing.start(["127.0.0.1","8.8.8.8"])

```

- While to monitor any number of sites, provide a list of their URLs

```iex

  iex> OctopusPing.start(["https://bbc.com", "https://cnn.com", "https://netflix.com"], :url)
```


