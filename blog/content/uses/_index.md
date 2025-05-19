---
title: "Uses"
extraHeadContent:
  - <link rel="stylesheet" type="text/css" href="/css/uses-page.css">
---

This is a ["Uses" page](https://uses.tech/), detailing some of the tools and other things I use.

# Technical

## Daily Drive

### Hardware

* **Laptop:** MacBook Pro 15-inch (2018), MacOS Monterey 12.7.1. A gift from my partner (when she in turn was gifted a laptop by her sister) when I quit my job in 2022. I'd like to experiment with a Linux-based daily driver (especially a [Framework](https://frame.work/), or I've heard good things about Linux on Thinkpads), but you can't beat free!
* **Keyboard:** [Kinesis Advantage 2](https://kinesis-ergo.com/shop/advantage2/). It took me about a month to get back up to my usual typing speed after buying this, but the benefits in terms of (lack of) wrist pain are incalculable. And I don't even use the super-leet foot-pedal to switch configuration layouts!
* **Mouse:** Some kind of Razer something that I was gifted by an old housemate.
* **Screens:** Dell 34" Superwide Curved Monitor, plus a LG 32" rotated 90 degrees. I use the latter solely for Slack, Music, and Calendar, whereas the former (in central view) rotates between browser, IDE, terminal, and whatever else (using [Rectangle](https://rectangleapp.com/)).
* [AV Access KVM](https://www.amazon.com/gp/product/B0CP4PD3SM). I only acquired this recently. It's...fine. Unfortunately Macs don't seem to support two external monitors on a single USB-C, so I have to have one of my external monitors directly wired to my work laptop - but that's ok, personal work rarely needs more than my main screen anyway.

### Software

* **IDE:** Visual Studio Code. I used to be a devotee of IntelliJ, but VS Code is the norm at work and it's been easier just to switch than to deal with differing configuration standards, and I don't want to have different IDEs for personal and professional work. I will say that it seems to have lower memory consumption so I can still have it open in the background when I play Factorio!
* **Browser:** Firefox. Continuing to use Chrome in 2024 is just plain baffling. I've yet to hear a compelling case for Edge or IE, or any of the smaller browsers.
* **Terminal:** [Kitty](https://sw.kovidgoyal.net/kitty/). I ditched [iTerm 2](https://iterm2.com/) on principle when they started introducing AI[^ai-optin]. So far they have seemed pretty much equivalent tbh.
  * Honourable mention to [Warp](https://www.warp.dev/), which I would definitely pick as a terminal if I was starting out _today_ (if they took out the AI nonsense). It provides out-of-the-box a lot of the customization and usability that I've spent years building up in my own dotfiles.
* [Bitwarden](https://vault.bitwarden.com/) for password management. I'd be interested in moving to self-hosted, but I'd want my backups to be _way_ better-tested before doing so - this is a real central point of failure for life!
* [Rectangle](https://rectangleapp.com) is a super-useful tool to rearrange windows on Mac.
* [fzf](https://www.freecodecamp.org/news/fzf-a-command-line-fuzzy-finder-missing-demo-a7de312403ff/) ([direct GitHub link](https://github.com/junegunn/fzf), but that article does a better job of explaining the value) for Fuzzy Find in the terminal.
* [Tailscale](https://tailscale.com/) for VPN. Believe the hype - it's magical.

## Homelab

### Hardware

* Three Raspberries Pi, a PowerEdge R430 that I got cheap and refurbished thanks to a tip from a friend, and another PE R430 that I bought off that same friend when he moved from the Bayeria to New York City.
* [iX Systems](https://www.ixsystems.com/) [TrueNAS R-Series](https://www.truenas.com/r-series/), 64GB RAM, 1x1.9TB SSD, 7x6TB HDD, 4xEmpty for expansion. Probably overkill, but I'd rather give myself some room to grow than have to deal with data migrations and repooling regularly!
* [Sysracks 12U 35" Rack](https://www.amazon.com/gp/product/B09KK678CN).
* [Quotom Mini PC](https://qotom.net/) w/ 8GB RAM, 64GB SSD, running [OPNSense](https://opnsense.org/) as Firewall and Router
* [Ubiquiti UniFi AP AC Pro](https://store.ui.com/us/en/products/uap-ac-pro). I set this up about 4 years ago, and I remember it being a real arse to get working with multiple false starts, but since then it's been pretty much flawless. I briefly experimented with an Eero mesh but that dropped out and needed a restart about every couple of weeks.

### Software

#### Utilities/Infrastructure

* [k3s](https://k3s.io/) is a super-simple way to install a Kubernetes cluster on "_something as small as a Raspberry Pi_". I'm sure it's probably missing some of the bells-and-whistles of the more fully-featured installations, but I've never hit any limitations that mattered to me. You can see the setup in the [pi-tools](https://github.com/scubbo/pi-tools/tree/main/scripts-on-pi)[^out-of-date-naming] repo that I use to configure my homeserver. Configuration and installation is [just these two lines](https://github.com/scubbo/pi-tools/blob/main/scripts-on-pi/controller_setup/1.sh#L67-L70), though there are another 70 or so lines of installing convenience resources (which I should really migrate to a full GitOps location, but eh, who has the time?)
  * [Helm](https://helm.sh/) and [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) are invaluable for defining and deploying Kubernetes applications, respectively.
  * I have really enjoyed what tinkering I've done with [cdk8s](https://cdk8s.io/) for Infrastructure-As-Code, but haven't used it in earnest yet. I have been able to use some [jsonnet](https://jsonnet.org/) to achieve some [pretty terse application definitions](https://gitea.scubbo.org/scubbo/helm-charts/src/branch/main/app-of-apps/edh-elo.jsonnet), though.
  * [`democratic-csi`](https://github.com/democratic-csi/democratic-csi) is an astonishingly "plug-and-play" dynamic storage provider for Kubernetes. With the exception of the one time I had to restart all the pods when they got into a funky state after a power outage took down the whole cluster, I often forget that it's there.
* [Gitea](https://about.gitea.com/) as my [Git forge](https://gitea.scubbo.org); hosting repos and Docker images, and executing workflows with [Gitea Actions](https://docs.gitea.com/usage/actions/overview)
* [Vault](https://www.hashicorp.com/en/products/vault) for Secrets management (See [here]({{< ref "/tags/vault" >}}) for some examples of what I've done with it!)

More detail to follow! TL;DR - Grafana, OpenProject, Jellyfin, Crossplane, KeyCloak, HomeAssistant.

[^ai-optin]: Yes, I know it was opt-in. It still indicates decision-making that I don't want to support.
[^out-of-date-naming]: the naming is somewhat out-of-date, since I've added a non-Pi PowerEdge to the cluster - but hey, all engineers know there's nothing to permanent as a temporary name!
