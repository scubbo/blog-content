---
title: "Weeknotes the Third"
date: 2025-03-16T23:41:15-07:00
tags:
  - Gitea
  - Homelab
  - K8s
  - Weeknotes

---
I had intended to write this weeknotes on the amusing rabbit-hole of yak-shaving I'd fallen down:
<!--more-->
* I found that a likely cause for [Keycloak]({{< ref "/tags/keycloak" >}}) stopping working on my system is that it [recently changed to only support traffic over HTTPS](https://github.com/keycloak/keycloak/issues/30977#issuecomment-2208679081).
* So I want to finally get around to using [LetsEncrypt](https://letsencrypt.org/) on my system, as per [this guide](https://adamtheautomator.com/letsencrypt-with-k3s-kubernetes/#Ensuring_Seamless_Certificate_Renewals_with_a_ClusterIssuer)
* But I should really take that opportunity to convert my [cert-manager definition](https://gitea.scubbo.org/scubbo/helm-charts/src/branch/main/app-of-apps/apps.yaml#L1-L27) to my [fancy new libsonnet-based approach](https://gitea.scubbo.org/scubbo/helm-charts/src/branch/main/app-of-apps/app-definitions.libsonnet).
* But before doing _that_, I want to install the [GitHub Vault Plugin](https://github.com/martinbaillie/vault-plugin-secrets-github) to provide automated scoped authentication for Gitea Actions, so that I don't need to keep refreshing the credentials for my [Commit Report Sync](https://gitea.scubbo.org/scubbo/commit-report-sync) tool.

...but while attempting to start writing the blogpost _on_ that rabbit hole, I found that the recent restart of my NAS (due to the manufacturer's sending me a replacement PSU[^wrong-molex]) had caused k8s dynamic PVC provision to get into a weird state, necessitating some force-deletion of PVCs and pods, meaning that my Gitea install's Redis cluster got into a broken state[^redis], so it's taken the better part of my entire weekend to even be able to publish this post[^publish].

Nobody ever said that self-hosting was easy 😝

[^wrong-molex]: which, irritatingly, turned out to have the wrong number of connectors, so I'll still need to keep using the current holdover one (which has the wrong form factor, so can't actually be installed _in_ the case but is sitting loose outside it in the rack) until they can send a proper replacement. But I didn't notice that until I'd already powered down the system. More fool me for assuming and not checking that the manufacturers would send the correct part!
[^redis]: shout out to [this SO answer](https://stackoverflow.com/a/63334594/1040915) for providing the command to force-reset a Redis cluster with unreachable masters: `redis-cli --cluster fix ONE_OF_HEALTHY_NODE_IP:PORT --cluster-fix-with-unreachable-masters`; and to [this discussion](https://forum.gitea.com/t/internal-server-error-500-on-site-administration-page/5347/14) for pointing out that setting `RUN_MODE=dev` in Gitea `app.ini` will print actual error messages on a `500` page.
[^publish]: and, at the time of writing (which is naturally pre-publication), I'm wary that Gitea Actions will probably need some gentle resetting and reauthentication before it can execute the publish, too...EDIT: heh, yep - Jack-from-a-half-hour-later can confirm that the automated job to create a registration token for the runners was bugged out, meaning that the k8s secret containing the token contained incorrect data, and irritatingly that token was cached on the runner at `/data/.runner` (thanks to [this post](https://gitea.com/gitea/act_runner/issues/550#issuecomment-824492) for identifying that!) so even after I populated the secret with a correct token it was still picking up the incorrect cached one.
<!--
Reminders of patterns you often forget:

Images:
![Alt-text](url "Caption")

Internal links:
[Link-text](\{\{< ref "/posts/name-of-post" >}})
(remove the slashes - this is so that the commented-out content will not prevent a built while editing)
-->