# OctopusPing

**A concurrent network monitor.**

OctopusPing is a network monitor built to track the health of devices on your network such as routers, virtual machines, servers, switches etc... 

It is also capable of monitoring websites to ensure uptime and availability.


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


