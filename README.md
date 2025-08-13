# OctopusPing

**A concurrent network monitor**

## Give it a spin with the following examples

**To monitor a bunch of network devices, provide a list of their IP addresses**
```iex

  OctopusPing.start(["127.0.0.1","8.8.8.8"])

```

**While to monitor any number of sites, provide a list of their URLs**

```iex

  OctopusPing.start(["https://bbc.com", "https://cnn.com", "https://netflix.com"], :url)
```


