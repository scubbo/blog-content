---
title: "Accessing Homelab Services Over Tailscale"
date: 2026-03-30T12:00:00-07:00
tags:
  - homelab
  - tailscale
  - opnsense
  - dns
  - written-by-ai

---
I've been using [Tailscale](https://tailscale.com/) as the VPN for my homelab for a while now, but I'd never actually tried to access my internal services from a remote location until recently. Turns out, just being on the tailnet doesn't mean everything magically works - there were a few layers of configuration (and one *very* long detour) between _"connected to Tailscale"_ and _"watching Jellyfin from a hotel room."_[^jellyfin-tailscale]
<!--more-->

**A note on authorship**: As I discussed in [my Authentik post]({{< ref "/posts/switching-to-authentik" >}}), I don't believe in passing off LLM-generated writing as my own. This post was written by Claude based on notes from a debugging session we worked through together. I've reviewed it for accuracy and edited where needed, but the prose is substantially LLM-generated. I'm making an exception to my usual hand-written rule here because the alternative was _"not writing this post at all"_ - and I think the information is genuinely useful to anyone running a similar setup. If the tone feels slightly off from my usual writing, now you know why.

## The Problem

All my internal services live behind Traefik on my `.avril` domain[^domain-name]. From the LAN, `radarr.avril` resolves just fine - OPNsense's DNS knows about these hostnames. But from a different network, connected over Tailscale:

```
$ nslookup radarr.avril
** server can't find radarr.avril: NXDOMAIN
```

Interesting. But:

```
$ nslookup radarr.avril 192.168.1.1
Name:    radarr.avril
Address: 192.168.1.13
```

So OPNsense *knows* the answer - Tailscale just isn't asking it. That makes sense: Tailscale overrides your system DNS when active, and whatever upstream resolvers it's using have no idea what `.avril` is. The home router is the only nameserver that does.

## Fix 1: Tailscale Split DNS

Tailscale has a [Split DNS](https://tailscale.com/kb/1054/dns/) feature in the admin console that's designed for exactly this. You can tell it _"for queries matching this domain, ask this specific nameserver."_ I configured:

- Domain: `avril`
- Nameserver: `100.80.219.48` (OPNsense's Tailscale IP)

The important thing here - and I did get this wrong on my first attempt - is that you have to use the *Tailscale* IP (`100.x.x.x`), not the LAN IP (`192.168.1.1`). The entire reason you're doing this is that you're *not on the LAN*. The LAN IP isn't routable from a remote network; the Tailscale IP is. It's obvious in hindsight, but it tripped me up for a few minutes.

## Fix 2: OPNsense Firewall Rules

Split DNS configured, I tried again. Still nothing - DNS queries to OPNsense's Tailscale IP just timed out. The queries were reaching OPNsense (I could see them arriving at the OS level), but getting silently dropped.

The root cause here is one of those things that's completely logical once you understand it, but deeply confusing until you do: OPNsense has an abstraction layer called "Interfaces" that sits between physical/virtual network devices and the firewall rule engine. A network device - whether it's a physical NIC like `igb0`, a VLAN like `igb0_vlan10`, or a virtual tunnel like `tailscale0` - exists at the FreeBSD OS level regardless of whether OPNsense knows about it. But OPNsense can only *apply firewall rules* to devices that have been "assigned" as Interfaces.

`tailscale0` existed; it was passing traffic at the OS level. But it wasn't assigned as an OPNsense Interface, which meant no firewall rules applied to it, and OPNsense's default-deny policy silently dropped everything.

The fix:

1. **Interfaces → Assignments** → add `tailscale0` as a new interface → enable it
2. **Firewall → Rules** → add a rule on the new Tailscale interface allowing DNS traffic (port 53)

After that, `nslookup radarr.avril` worked from the remote machine. Progress!

## Fix 3: Subnet Routing

DNS was resolving, but the browser still couldn't reach anything. The reason became clear when I looked at what `radarr.avril` resolved *to*: `192.168.1.13`, the LAN IP of my Traefik ingress. From a remote network, that address means nothing - it's a private IP on a network I'm not connected to.

The solution is [Tailscale subnet routing](https://tailscale.com/kb/1019/subnets/): you designate a node on the tailnet as a subnet router that can forward traffic to a local network. I enabled OPNsense as a subnet router advertising `192.168.1.0/24`, then approved the route in the Tailscale admin console[^approve-route].

With that in place, traffic to `192.168.1.13` from any tailnet node gets routed through OPNsense and onto the LAN. Everything works.

## The Detour: OPNsense Upgrades

You might have noticed I glossed over something in Fix 2. The *original* plan was to install the `os-tailscale` OPNsense plugin, which provides a clean interface for managing the Tailscale integration (including the interface assignment). But the plugin requires OPNsense 24.7.11 or later, and I was on 24.1.

OPNsense only supports sequential major version upgrades. My upgrade path looked like:

```
24.1.10 → 24.7.1 → 24.7.12 → 25.1 → 25.1.12 → 25.7.11 → 26.1.2
```

This took a while - not least because I didn't want to risk updating my router remotely while I wasn't actually home, and risk taking down Internet for my wife for days!

Two of the intermediate upgrades (24.7→25.1 and 25.1→25.7) failed when run from the CLI with _"Host does not resolve"_ errors, despite DNS working fine from the shell. Each time, the GUI's _"Check for Updates"_ → _"Upgrade"_ button worked without issues. My best guess is that Unbound DNS restarts during the CLI upgrade process, causing transient resolution failures that the upgrade script doesn't handle gracefully. The GUI presumably has different retry logic[^gui-upgrade].

## The Other Detour: AdGuard Home

I was running [AdGuard Home](https://adguard.com/en/adguard-home/overview.html) as a DNS filtering layer on OPNsense via the `os-adguardhome-maxit` plugin from the mimugmail third-party repo. It stopped working during the 24.7.12 upgrade and refused to start for the rest of the upgrade journey.

After finally reaching 26.1, I tried to diagnose it. Running the binary in the foreground revealed:

```
unknown current schema version 32
```

What happened: during one of the intermediate OPNsense versions, a *newer* version of AdGuard Home had transiently been installed and run. That newer version migrated the configuration schema forward to version 32. But the binary got rolled back to v0.107.69 (the version shipped by the plugin), which doesn't understand schema 32.

The plugin only shipped v0.107.67. Schema version 32 requires v0.107.71 or later. The fix was manual: download the FreeBSD amd64 build of AdGuard Home v0.107.73 from [GitHub releases](https://github.com/AdguardTeam/AdGuardHome/releases) and replace the binary[^manual-binary].

## What I Learned

The three-layer fix (Split DNS → firewall rules → subnet routing) makes a lot of sense in retrospect - each layer solves a distinct problem (DNS resolution, traffic acceptance, IP reachability). But the OPNsense Interface concept was the real "aha" moment for me. The mental model of _"a network device exists at the OS level, but the firewall engine only sees assigned Interfaces"_ explained not just this problem but clarified several other OPNsense behaviours I'd been fuzzy on. I took the opportunity to do some interactive learning with a separate agent session - having it quiz me on my understanding, identify gaps, introduce concepts to fill them, then test me again. I've used this technique a few times now for topics that I'd previously considered too opaque to start learning on my own, and it's worked wonders.

The upgrade saga was a reminder that homelabs accumulate entropy. I'd been putting off the OPNsense upgrade for... a while. Each deferred upgrade makes the next one scarier, which makes you defer it longer, which makes it scarier. Classic vicious cycle. As SREs like to say (or, they should!) - _"If it hurts, do it more often"_.

I could probably sidestep this whole DNS setup by [assigning Tailscale names to all my Kubernetes services](https://tailscale.com/docs/kubernetes) and accessing them directly that way - but honestly, I'm happy with the self-run DNS setup I have for now. It gives me a single consistent naming scheme whether I'm on the LAN or remote, as well as letting me learn more-generic technologies like DNS rather than relying on out-of-the-box solutions. That's the whole point of a Homelab, after all!

[^jellyfin-tailscale]: Well, as long-time readers know, I actually have a solution specifically for Jellyfin - see [Jellyfin over Tailscale]({{< ref "/posts/jellyfin-over-tailscale" >}}). In fact I was trying to access a different service.
[^domain-name]: A TLD I use internally, backed by OPNsense's Unbound DNS. Yes, I know `.avril` is not a reserved TLD and could theoretically conflict with a future ICANN delegation. I'll cross that bridge if it ever comes.
[^approve-route]: This two-step process (advertise on the node, then approve in the admin console) is a nice security model - a compromised node can't unilaterally start routing traffic for arbitrary subnets.
[^gui-upgrade]: Or maybe the GUI upgrade just restarts Unbound less aggressively. I didn't investigate further since I had, at that point, approximately four more major versions to go.
[^manual-binary]: With the obvious caveat that a future plugin update will probably overwrite my manually-updated binary with the older version. Future-Jack's problem.
