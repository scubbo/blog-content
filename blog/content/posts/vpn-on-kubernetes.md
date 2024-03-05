---
title: "VPN on Kubernetes"
date: 2022-12-15T22:28:24-08:00
tags:
  - homelab
  - k8s

---
I was surprised to find that there's not much discussion of putting Kubernetes pods behind a VPN. Given how useful both tools are, you'd think more people would use them in concert.
<!--more-->
The only guide I could find was [this](https://docs.k8s-at-home.com/guides/pod-gateway/), which sadly links to a [deprecated and Read-only repo](https://github.com/k8s-at-home/charts/issues/1761). Thankfully, the charts still work, though I had to do some extra tweaking and digging around in `values` to get them to work. You can see [here](https://github.com/scubbo/pi-tools/commit/699032d6d69b5a54a5a303d410c9565aa03ab470) the commit where I introduce and test the VPN[^1], though I haven't yet tried putting any "real" services behind it - just a single pod for testing that the connection is intercepted correctly. It looks like opening up ports for service isn't too hard, though!


[^1]: On ProtonVPN's implementation of OpenVPN only. I don't have access to other VPN providers and I'm not going to pay for them just to test; and I wasn't able to get Wireguard to work, despite it being an apparently simpler protocol. 