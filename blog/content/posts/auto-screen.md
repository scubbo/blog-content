---
title: "Auto Screen"
date: 2022-05-16T17:42:11-07:00
tags:
  - homelab
---
`screen` ([Wikipedia](https://en.wikipedia.org/wiki/GNU_Screen)) is a Unix tool that starts a persistent session on a remote machine, allowing you to detach from that session while keeping any running processes alive. It's really useful when executing a long-running process over an unstable ssh connection. There are other ways to achieve that aim (like [Background Processes](https://en.wikipedia.org/wiki/Background_process)), and other features of `screen` itself (like fitting multiple panels in a single window), but that's what I primarily use it for.
<!--more-->
As I've been building out my homelab, I've had the need to ssh to a bunch of different devices, and it's been awkard to remember to start a new screen session every time I log in. Fortunately, the [SSH config file](https://man.openbsd.org/OpenBSD-6.2/ssh_config#RemoteCommand) permits the specification of a `RemoteCommand` directive, which will be "_execute[d] on the remote machine after successfully connecting to the server_". So, with an `~/.ssh/config` that looks like this:

```
Host host_nickname
  HostName hostname.avril
  RequestTTY force
  RemoteCommand screen -D -RR -p +
```

I can, by typing `ssh host_nickname`, immediately connect to the existing `screen` session on `hostname.avril`[^1] (detaching it if it already exists somewhere else), and create a new pane within it. I'd like to tweak this to only open a new pane if there's a process already running in every existing pane (otherwise, open to the first "idle" pane), but that will probably be way more complex!

If I wanted, I could define `User` and `IdentifyFile` in that `Host` definition, but I already have those defined in a `Host *` wildclass lower down the file (_lower down_ is important! SSH Config binds in discovery order, not in specificity order - so if you have a `Host *` definition at the top of the file, you won't be able to override it anywhere else).

[^1]: Why "`avril`"? It's the local domain name I use for my network - all my homelab machines are assigned the domain name `<hostname>.avril` by my OPNSense Router's DNS configuration. But why Avril? Because it's the name my partner and I use for our home? Why? Because, during the buying process, everything was [so complicated](https://www.youtube.com/watch?v=5NPBIwQyPWE)...
