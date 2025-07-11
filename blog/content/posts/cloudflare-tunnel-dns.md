---
title: "Cloudflare Tunnel DNS"
date: 2022-08-22T16:05:39-07:00
tags:
  - cloudflare-tunnels
  - homelab
  - k8s
  - meta

---
I use [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/) to expose services (like this blog!) to the public Internet while remaining protected by Cloudflare's infrastructure. While attempting to add a new service, I noticed that there were two steps required:
* Updating the configuration deployed to the tunnel daemon, mapping the internal service to its externally-accessible name
* Updating Cloudflare's DNS entries to map the external name to the Cloudflare tunnel

Although the first step is easily automated with the [`cloudflare/cloudflared` image](https://hub.docker.com/r/cloudflare/cloudflared), the second isn't so simple - there's no single command to update all exposed sites, so the logic would need to parse the config file to determine the set of all sites, and the `cloudflared` image doesn't include tools to do so.
<!--more-->
My solution was [this code](https://gitea.scubbo.org/scubbo/cloudflaredtunneldns), which creates a Docker image containing a [`dns_update.sh`](https://gitea.scubbo.org/scubbo/cloudflaredtunneldns/src/branch/main/dns_update.sh) script which can perform the required DNS updates. It's [published to my private Docker Registry](https://gitea.scubbo.org/scubbo/cloudflaredtunneldns/src/branch/main/.drone.yml#L27-L36) (described in [this post]({{< ref "/posts/secure-docker-registry" >}})), and used as an `initContainer` in a Kubernetes deployment [like so](https://github.com/scubbo/pi-tools/blob/main/k8s-objects/cloudflared/manifest.yaml#L19-L30).

It still feels a little strange to me that I had to hack this solution up myself. I would have expected an option on `cloudflared tunnel run` that sets DNS records before starting, or a way to call `cloudflared tunnel route dns <tunnel_name>` without specifying a particular domain name in order to update them all. I plan to open an issue on the Cloudflared repo asking if this is a feature that should be supported - and hopefully implement it myself, if I can!

**EDIT:** As described [here]({{< ref "/posts/rebuild-from-scratch" >}}), I got frustrated at the circular dependency this introduces (Tunnels can't come up until the `initContainer` runs; `initContainer` can't fetch the image if the Gitea instance isn't available; Gitea instance isn't available if the tunnels aren't up) that I [hard-coded the DNS-update script into a ConfigMap](https://github.com/scubbo/pi-tools/commit/bd1e178e1ccf179068d6d98e1cfab6de26a82960).
