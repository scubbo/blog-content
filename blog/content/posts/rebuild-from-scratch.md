---
title: "Rebuild From Scratch"
date: 2023-02-07T19:52:44-08:00
tags:
  - CI/CD
  - homelab
  - k8s
  - observability

---
Observant readers of this blog, refreshing every day desperate for new content, will have noticed that the last blog post - dated 2022-12-31 - actually went live in the middle of January. My k3s cluster, which had always been a bit rickety, finally gave up the ghost in late December, and two of the nodes needed to be fully reimaged before I could start it back up again.  
<!--more-->
It wasn't a total loss, though - I learnt some things along the way!

## Avoid circular dependencies at cold-start

My previous setup for this cluster had a circular dependency:

* I use [Cloudflare tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)[^tunnel-article] to expose my Kubernetes pods to the outside world - but since adding a new domain name also requires updating Cloudflare's DNS to point _at_ the tunnel, I used [this code](https://gitea.scubbo.org/scubbo/cloudflaredtunneldns) as an `initContainer` to run those updates. The image for this code is hosted on my Gitea server (which, as well as a Source Control system, is also an Image Registry).
* Pulling the image from Gitea requires that it's available on the external domain name - [Gitea only supports interactions on a single URL](https://github.com/go-gitea/gitea/issues/22033), even if your internal DNS is set up to have an internal-only name as well as the externally-available one.

So, at cold-start, we have a deadlock - the tunnels won't start up because they can't access the `initContainer` image, which is unavailable because the tunnels aren't started up.

There are a couple of ways around this:
* Set up an internal-only Gitea server which only hosts the Cloudflare `initContainer` script
* Rely on the fact that the DNS entry for Gitea is _probably_ already present on a cold-start, and have the initContainers "fail open" (i.e. progress to starting the Cloudflare tunnels even if the `initContainer` image can't be found[^docker-in-docker])

Both of which sounded like more hassle than they were worth. I took a bodgey-but-effective solution of [extracting the actual script logic to a ConfigMap within the Kubernetes manifest](https://github.com/scubbo/pi-tools/commit/bd1e178e1ccf179068d6d98e1cfab6de26a82960). This way, there's no Gitea dependency - the Cloudflare tunnel Pod definition contains the `initContainer`'s code within itself.

It ain't pretty, but it works! If I had the dev-hours to make this properly enterprise-grade, I'd either do the internal-only Gitea instance approach, or see if there's some magic possible with nginx to make Gitea _think_ it's being called on a given name when called from an external name or an internal one - but ain't nobody got time for that.

## Don't overtax your SD cards

The fact that Raspberries Pi run on SD cards is both a strength and a weakness. A strength in that their storage is inexpensive and widely available; a weakness in that their storage is among the more fallible formats in common usage. I was running into particular problems because the `/var/lib/rancher/k3s` directory would rapidly fill up the cards, leading to instability. It's possible to move that data to a different location with judicious use of [symbolic links](https://mrkandreev.name/snippets/how_to_move_k3s_data_to_another_location/) - or you can even start up the nodes with a `--data-dir` argument pointing elsewhere - but I wanted to go one step further and hard-limit the size this directory could grow to[^image-purging], by creating a virtual drive (physically on an external hard drive, but logically mounted on the SD card) with limited space:

```
$ mkdir -p /mnt/EXTERNAL_DRIVE/k3s-data
$ cd /mnt/EXTERNAL_DRIVE/k3-data
# The below creates a 20Gb file, since dd uses a block size of 512 bytes
# At the time of checking (2023-02-03), k3s' data was ~6Gb, this leaves room for expansion
$ dd if=/dev/zero of=k3s.ext4 count=40960000 status=progress
$ sudo /sbin/mkfs -t ext4 -q k3s.ext4 -F
$ sudo systemctl stop k3s-agent # Or `k3s` if this is a control-plane node
$ sudo mount -o rw k3s.ext4 /mnt/EXTERNAL_DRIVE/temp_mount
$ sudo mv /var/lib/rancher/k3s /mnt/EXTERNAL_DRIVE/temp_mount
$ sudo umount /mnt/EXTERNAL_DRIVE/temp_mount
$ echo "/mnt/EXTERNAL_DRIVE/k3s-data/k3s.ext4 /var/lib/rancher ext4 defaults 0 2" >> /etc/fstab
$ sudo mount -a
$ sudo systemctl restart k3s-agent # or `k3s`
```

## Oncall is overkill for a homelab

I'd spent *ages* trying to get [Grafana Oncall](https://github.com/grafana/oncall) working on my setup - a lot of the helm configuration was [poorly](https://github.com/grafana/oncall/commit/4add1636083f97e33c4e3e8326989a2dbc1ac813)-[documented](https://github.com/grafana/oncall/issues/1235#issuecomment-1412361272) or [apparently-incorrect](https://github.com/grafana/oncall/issues/1104). Nevertheless, I persisted, since I knew that it would be pointless to keep implementing features on a possibly-unstable cluster if I wasn't able to receive alerts when it was having issues.

Until one night I was poking around and found that vanilla Grafana has the ability to send Telegram alerts directly. Given that I'm just a single person (who doesn't need oncall rotation support), this is perfectly fine for my needs!

That said, recent changes have meant that Oncall is now [easier to set up](https://github.com/scubbo/pi-tools/tree/898c06d7c5193d1b7716dde4ba5c572f88de21bb/k8s-objects/helm-charts/grafana-oncall) than I had [previously found]({{< ref "/posts/grafana-oncall" >}}) - RabbitMQ clusters can now be run directly from the Helm chart on an `arm64` machine rather than having to install them separately, for instance! Still, though - not worth it for a single-operator system.

[^tunnel-article]: Referenced previously [here]({{< ref "/posts/cloudflare-tunnel-dns" >}}), and inspired by [this article](https://eevans.co/blog/garage/)
[^docker-in-docker]: I guess this would probably require running Docker-in-Docker, since I don't think it's possible to tell Kubernetes "_This initContainer doesn't matter, don't fail if you can't fetch the image_" - so I'd have to run a standard image which _itself_ tries to download-and-run the DNS-setting image, but fails gracefully if it can't do so.
[^image-purging]: [this answer](https://github.com/k3s-io/k3s/issues/1900#issuecomment-644453072) suggests that it should be possible to have k3s limit its own usage, but anecdotally messing with those values didn't seem to reduce space usage.