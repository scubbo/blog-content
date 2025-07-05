---
title: "A New Start"
date: 2025-07-04T17:21:42-07:00
tags:
  - Cloudflare-Tunnels
  - Homelab
  - K8s
  - Meta
  - Starting-Over

---
A couple of days ago, the Hard Drive that I'd initially been using as my NAS (before investing in a beefy TrueNAS setup) failed. Since my homelab Kubernetes cluster predated the TrueNAS, this was the drive on which I'd stored configuration files for the cluster itself, which meant the cluster immediately went down. I probably _could_ have salvaged it while flying the plane, but this was a great opportunity to start again from scratch using the various lessons I'd learned over the years.
<!--more-->
You can follow along with the setup [here](https://github.com/scubbo/homelab-configuration).

# What's changed

## Out with Gitea, In with GitHub

I still resonate with the reasons why I chose to self-host Gitea in the first place - one of my primary motivations for self-hosting is a(n admittedly-symbolic) gesture against centralization of technical tools. That said - as detailed [here](https://github.com/scubbo/homelab-configuration/blob/main/README.md) - there are pretty convincing reasons to compromise on that particular point. It makes me sad, but it is what it is; gotta pick your battles.

## High-Availability Cluster

Although I don't think I ever found this explicitly stated in k3s's documentation, I'm 99% sure that it's not possible to upgrade from a single-control-plane-node cluster to a high-availability one. This was a nice opportunity to do so!

As usual with [k3s](https://docs.k3s.io), installation couldn't have been simpler - just one prerequisite step of [setting up an external Datastore](https://docs.k3s.io/datastore), and an extra `--datastore-endpoint` parameter to the [launch commands](https://docs.k3s.io/datastore/ha#2-launch-server-nodes), and that was that!

Docker made spinning up Postgres super-easy[^why-owned-by-root]:

```yaml
# docker-compose.yaml
services:
  postgres:
    image: postgres
    ports:
      - "5432:5432"
    environment:
      POSTGRES_PASSWORD: FILL_IN_YOUR_DESIRED_PASSWORD_HERE
    volumes:
      - /path/to/a-dir/on-your-host-machine-owned-by-root:/var/lib/postgresql/data

# Probably a more-sophisticated way to do this would be with `systemctl`,
# but I don't know much about that other than basic commands yet
# `$ docker compose up -d`
```

## Using IngressRoute for Argo

Per instructions [here](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#traefik-v30) (more docs [here](https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/crd/http/ingressroute/)) - although I haven't yet set up a [CertResolver](https://doc.traefik.io/traefik/https/acme/), so used a self-signed certificate.

Really I don't have any use-case that makes an IngressRoute preferable to a plain ol' Ingress - not using any middleware or complex Rules, nor observability - but this'd be a nice opportunity to try some of those out if desired!

## One `cloudflared` per application

I [found out](https://github.com/cloudflare/cloudflared/issues/739) that the pattern I'd been using for `cloudflared` previously - one installation that fanned out to various services - was not one envisioned or encouraged by the developers. For now, I've semi-manually created a deployment[^cloudflare-tunnel-example].

Ideally, of course, I'd use [Vercel's CDN](https://vercel.com/docs/edge-network), but it doesn't currently support the ability to serve from a locally-running application.

## Everything[^argo] in app-of-apps

Since I was learning about Kubernetes tooling as I went, you can chart my learning by looking at the sophistication of my configuration mechanisms - from [`cat`-ing config files straight to `kubectl apply`](https://github.com/scubbo/pi-tools/blob/main/scripts-on-pi/controller_setup/1.sh#L76-L129), through [`kubectl apply -f <url>`](https://github.com/scubbo/pi-tools/blob/main/scripts-on-pi/controller_setup/1.sh#L131), via [k8s manifests intended to be installed via Argo](https://github.com/scubbo/pi-tools/tree/main/k8s-objects)[^helm], into [Helm Charts](https://github.com/scubbo/pi-tools/tree/main/k8s-objects/helm-charts), finishing off with a (beautiful, if I do say so myself) [abstraction of common installation patterns](https://github.com/scubbo/homelab-configuration/blob/main/app-of-apps/app-definitions.libsonnet) so they can be expressed in [just a handful of lines](https://github.com/scubbo/homelab-configuration/blob/main/app-of-apps/blog.jsonnet) in [a single directory that Argo will scan app definitions](https://github.com/scubbo/homelab-configuration/tree/main/app-of-apps). Upgrading any of these applications to "_the new way_" always felt like more trouble than it was worth; but now I'm spring-cleaning, everything can be cleaner and more uniform!

## Everything on TrueNAS, no Longhorn

I experimented with [Longhorn](https://longhorn.io/) a couple of years back and found it frankly unsatisfactory. When it worked, it worked pretty well; but when it went wrong, the errors were inscrutable, and even when you knew what to do, recovery was difficult and time-consuming. There were several nights when I stayed awake for hours, shuffling replicas around and whack-a-moling erroring pods. Maybe I'd done something wrong in my setup, who knows; but I'm not sad to see it gone.

# Next priorities

* Jellyfin. The only service that matters, as far as the rest of my household's concerned!
* Backups of data from the k3s HA postgres database. It would be ironic and frustrating to lose this cluster in a similar way to the previous one!
* Double-checking backups from the TrueNAS. I get regular confirmations that they're _running_, but you know what they say about untested backups...
* A [LetsEncrypt Cert Resolver](https://doc.traefik.io/traefik/https/acme/#certificate-resolvers)[^cluster-issuer]
* Set up a catch-all website on `gitea.scubbo.org` acknowledging that it's gone away
  * I _might_ do a find-and-replace on blog posts that mention it. Or, that'd be a cool use-case for some kind of rendering built-in by Hugo itself...
* Automation (probably via [Operators](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/), which I haven't yet played with; or [Crossplane](https://www.crossplane.io/), which I have, and love) for:
  * Updates on my router's UnboundDNS for certain Ingresses[^no-wildcard]
  * per-service Cloudflared tunnel
* Reinstallation of [Vault](https://www.hashicorp.com/en/products/vault) and the [GitHub Token Plugin](https://martin.baillie.id/wrote/ephemeral-github-tokens-via-hashicorp-vault/) - I've hard-coded a secret to allow this blog's CD pipeline to succeed, but I don't want to do that any more than once. I'm _really_ hoping that the installation will magically come right back up again, pre-configured, when I reconnect to the PVC - fingers crossed...
* Monitoring. [Grafana]({{< ref "/tags/observability" >}}) was one of the first systems I tried to install on the Homelab, but newbie that I was, I couldn't really get my head around it[^datadog].


[^argo]: Except Argo - gotta bootstrap somehow!
[^why-owned-by-root]: I learned during this process an easy way to find the runas user of an image - `docker run --rm <image_name> id`.
[^helm]: "_is this where I'm supposed to learn helm?_" - yes, past Jack, it was; but that's ok, you were doing your best!
[^cloudflare-tunnel-example]: following [this example](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/deployment-guides/kubernetes/), attempting to API-ify as much as I can with [these steps](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel-api/) - though note an apparent [issue with the documentation](https://github.com/cloudflare/cloudflare-docs/issues/23461).
[^cluster-issuer]: and _maybe_ a [LetsEncrypt ClusterIssuer for `cert-manager`](https://cert-manager.io/docs/tutorials/getting-started-aks-letsencrypt/#create-a-clusterissuer-for-lets-encrypt-staging)? I'll be honest, I don't actually know if I need the latter if I already have the former. I guess `cert-manager` would permit TLS'd communication _between_ applications on the cluster? Which will probably be helpful when I come back around to Keycloak, as I [recall that that was the issue previously]({{< ref "/posts/weeknotes-the-third" >}}).
[^no-wildcard]: apparently there's a [known issue](https://github.com/opnsense/core/issues/4049) where OPNSense Unbound cannot support wildcard overrides - although, I do see a new comment since my last that purports to solve it...
[^datadog]: compromising my technical morals by moving from Gitea to GitHub is one thing; but if you ever see me considering using DataDog on a homelab, please stage an intervention.
