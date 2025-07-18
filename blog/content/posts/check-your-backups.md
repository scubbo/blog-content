---
title: "Check Your Backups"
date: 2021-12-05T12:18:43-08:00
tags:
  - homelab
---
I fully intend to write a full blog-post as a follow-up to my [previous post]({{< ref "/posts/my-first-post" >}}) at some point, detailing some of the quirks of this setup and issues that I ran into - but I just got a timely reminder of the importance of checking backups, and wanted to pass it on to you.
<!--more-->
I have a few Raspberries Pi on my home network. One is running [pi-hole](https://pi-hole.net/) for network-wide ad blocking, one hosts the [Home Assistant Operating System](https://www.home-assistant.io/), one is a [Kodi](https://kodi.tv/)-box, and another is for "everything else" - [Jellyfin](https://jellyfin.org/) as a media server, [Prometheus](https://prometheus.io/) and [Grafana](https://grafana.com/) for monitoring, and anything else that takes my fancy. In keeping with my enthusiasm for Infrastructure As Code, I made sure to note down all the installation instructions I'd used [here](https://github.com/scubbo/pi-tools/tree/main/scripts-on-pi), but I'd never been prompted to actually use it. Recently, however, the "misc" Pi's performance has been gradually degrading (I suspect, but have no proof of this, that it's because of the patchwork of conflicting Python package versions I've installed. As [Matthew Duggan says](https://matduggan.com/mistakes/) - "_Nobody knows how to correctly install and package Python apps_"), and I wanted to make a fresh install to get a clearer view of the situation.

Thankfully, the install scripts worked nearly flawlessly. There were a few hiccups to work around and [improvements to be made](https://github.com/scubbo/pi-tools/commit/3d9a0c939791a13b95f28e0ee07942547ba981ad), but broadly speaking, the transfer of functionality to a new install was a success.

I was in the lucky situation that I still had a mostly-functional existing system, so if anything had gone wrong in the backup process I probably have reconstructed it - but that's not always the case. A backup or backup-restore process that hasn't been tested cannot be assumed to be usable. Go check yours now!

There's still a long way to go in improving this:
* I suspect that sharing the _same_ SSH key to all my Pis (which I also use for everything else) is probably sub-optimal compared with giving them a dedicated key that is only good for downloading setup scripts (or even, now I come to think of it, downloading directly from the GitHub API, which _shouldn't_ need authentication for public repos).
* I still haven't figured out how to back up a Grafana dashboard, so the lovingly-crafted dashboard I created to monitor my systems has been lost.
* I'm only backing up the install scripts for functionality. The actual data - configuration, media, etc. - is stored on an external hard-drive, and _that_ isn't currently RAID-enabled or otherwise backed up anywhere.
* I don't have any setup instructions for my pi-hole, though that's simple enough that it shouldn't be a big problem (The Home Assistant is backed regularly backed up with [these scripts](https://github.com/scubbo/pi-tools/tree/main/hass-backup)).
* The new Pi got assigned a different LAN IP, probably (I'm guessing based on limited knowledge of DHCP) because it connected to the network before I set the `hostname`. I suspect that any clients that rely on direct IP connection (i.e. those that cannot use [Avahi](https://www.avahi.org/) - which probably include Kodi clients for Jellyfin) will need to be updated.
* I don't have a process set up for distributing [dotfiles](https://github.com/scubbo/dotfiles) to my Pis - in fact, I don't even have a Pi-specific `.zshrc` (I have a generic one, then specific ones for my work laptop and work desktop).
* I'd like to capture the output of all the installation components and route them to a dedicated log file, and only have my own logging output to stdout. I know I can do that on a command-by-command basis by appending `>> logfile`, but I [wonder](https://en.wikipedia.org/wiki/Ward_Cunningham#%22Cunningham's_Law%22) if there's a way to redirect output by default for an entire `.sh` file, and allow certain `echo`s to bypass that to `stdout`?
* I'm reliably informed that I should be using [Kubernetes](https://kubernetes.io/) for managing containerized applications anyway ;)
