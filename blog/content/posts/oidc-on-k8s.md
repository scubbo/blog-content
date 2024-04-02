---
title: "OIDC on K8s"
date: 2024-04-01T20:36:32-07:00
tags:
  - dns
  - homelab
  - k8s

---
I just configured OIDC login for the first service on my Homelab.
<!--more-->
The first step was picking a provider - but thanks to the [awesome self-hosting guide](https://github.com/awesome-foss/awesome-sysadmin?tab=readme-ov-file#identity-management---single-sign-on-sso), I'd already narrowed it down to a shortlist, and [this post](https://old.reddit.com/r/selfhosted/comments/ub7dvb/authentik_or_keycloak/) helped me pick Keycloak over Authentik.

Unusually, there's no Helm chart listed in the [getting started guide](https://www.keycloak.org/getting-started/getting-started-kube), but the old standby of [Bitnami](https://github.com/bitnami/charts/tree/main/bitnami/keycloak) had an offering (though they did weirdly change the admin username from `admin` to `user`, which threw me off at first). [Installation via GitOps](https://gitea.scubbo.org/scubbo/helm-charts/commit/1d56a131b71315fb3c1fb2a3b2b39d099b0f605d) was a breeze now that I'm using [jsonnet](https://jsonnet.org/) to extract common Application setup boilerplate - though I did have to upgrade my ArgoCD installation from `2.7` to `2.10` to make use of `valuesObject` configuration.

The first application I wanted to integrate was Argo itself[^jellyfin-plugin], and thankfully there's a step-by-step [guide](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/keycloak/) available, which..._mostly_ worked[^realm].

## [It's not DNS...](https://www.cyberciti.biz/media/new/cms/2017/04/dns.jpg)

I did run into a problem, though - I'd entered an override on my OpnSense router (running Upbound DNS) for `keycloak.avril`[^avril] pointing to the k8s cluster, so that I could access it from my browser - but, apparently, the pods on the cluster don't delegate to that resolver, so I got an error `Failed to query provider "http://keycloak.avril/realms/avril": Get "http://keycloak.avril/realms/avril/.well-known/openid-configuration": dial tcp: lookup keycloak.avril on 10.43.0.10:53: no such host` when trying to login via SSO. At first I tried setting the `issuer` value in Argo's `oidc.config` to `http://keycloak.keycloak` rather than `http://keycloak.avril` (i.e. using the k8s internal DNS name for the service), which allowed Argo to talk to Keycloak, but then gave a DNS error when my _browser_ tried to connect to that host. I could have worked around this by also setting a `keycloak.keycloak` DNS override on the OpnSense Unbound resolver, but that felt hacky - and, besides, I wanted to understand Kubernetes' DNS setup a little better.

[This SO answer](https://stackoverflow.com/a/65338650/1040915) looked promising as a way to set overrides for k8s' CoreDNS - but, since my ConfigMap already had a `hosts` entry (presumably provided by [k3s](https://k3s.io/)?):

```
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
        }
        hosts /etc/coredns/NodeHosts {
          ttl 60
          reload 15s
          fallthrough
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
        import /etc/coredns/custom/*.override
    }
    import /etc/coredns/custom/*.server
  NodeHosts: |
    192.168.1.70 host1
    192.168.1.71 host2
    ...
```

I got an error `plugin/hosts: this plugin can only be used once per Server Block` when trying to add another (I'm not sure why that restriction exists tbh - the [docs](https://coredns.io/plugins/hosts/) make it clear that the plugin can be limited to a zone, so it seems reasonable to have multiple entries for multiple zones?). Handily, though, the plugin also allows listing overrides inline, so I was able to add an entry for `keycloak.avril` and everything worked as-desired!

```
...
hosts /etc/coredns/NodeHosts {
  192.168.1.70 keycloak.avril
  ttl 60
  reload 15s
  fallthrough
}
...
...
```

That worked, but still felt hacky. Now I was managing DNS overrides in two places rather than one. The docs do list a `forward` [plugin](https://coredns.io/manual/configuration/#forwarding) which looks like it should do what I want - but adding that (and removing the manual override in `hosts`):

```
...
 forward avril 192.168.1.1 # My OpnSense router IP
 forward . /etc/resolv.conf
...
```

...gave a slightly different error `failed to get token: Post "http://keycloak.avril/realms/avril/protocol/openid-connect/token": dial tcp: lookup keycloak.avril on 10.43.0.10:53: no such host` during callback in the OIDC process. Even opening up the `forward` to operate for all names (`.`) failed (though in this case it was back to the `Failed to query provider...` error).

🤷🏻‍♂️ at some point you've just gotta take a working solution (the inlined entry in `hosts`) and move forwards with it! This duplication isn't _too_ bad - I doubt there'll be _another_ system (other than OIDC) where I'll need both pods and my browser to be able to use the same DNS name. If there is, I'll return to this problem and try to crack it.

I do also see an `import /etc/coredns/custom/*.override` line in that configuration, which would be another promising avenue of investigation - and, hey, if I realize my intention of managing Unbound DNS entries via [Crossplane](https://www.crossplane.io/), both the Router Overrides and the CoreDNS configuration could be generated from the same source.


[^jellyfin-plugin]: Jellyfin would probably be next, though it looks like that's not natively supported and requires a [plugin](https://github.com/9p4/jellyfin-plugin-sso), or maybe "Keycloak + OpenLDAP" as per [here](https://old.reddit.com/r/selfhosted/comments/ed1z9e/sso_with_authorization_for_jellyfin_ombi_sonarr/fbffkfp/) - though at this point I haven't researched the difference between LDAP and SSO.
[^realm]: _Don't_ follow their instructions to work in the default realm `master`, though! [Keycloak docs](https://www.keycloak.org/docs/latest/server_admin/#the-master-realm) make it clear that you should "_Use the `master` realm only to create and manage the realms in your system._"
[^avril]: As long-time readers will remember, the name that my partner and I use for our house - and so, the name I use for any domain/realm/namespace/zone on our network - is "Avril", because the house purchase process _went and made things so complicated..._
