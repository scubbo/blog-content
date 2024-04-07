---
title: "Keycloak Backup"
date: 2024-04-06T17:34:34-07:00
tags:
  - homelab
  - keycloak
  - k8s

---
Setting up regular backup for my [Keycloak installation]({{< ref "/posts/oidc-on-k8s" >}}) was a lot trickier than I expected!
<!--more-->
Although there is a `kc.sh export` command on the image, there's a [long-standing bug](https://github.com/keycloak/keycloak/issues/14733) whereby the export process and the server clash for the same port. I went [down the rabbit-hole](https://github.com/keycloak/keycloak/issues/28384) with the Keycloak folks trying to workaround that - only to realize that, because the image doesn't come with `cron` installed, I wouldn't be able to schedule the `kc.sh export` on the main pod _anyway_, but would have to schedule it externally.

A [Kubernetes CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) was the obvious solution - but there were several hoops to jump through first:
* I needed to replicate an `initContainer` which, so far as I can tell, just [copies a directory](https://github.com/bitnami/charts/blob/main/bitnami/keycloak/templates/statefulset.yaml#L100) into [a PV](https://github.com/bitnami/charts/blob/main/bitnami/keycloak/templates/statefulset.yaml#L113-L115), only for that same PV [to get mounted at the original path again in the main container](https://github.com/bitnami/charts/blob/main/bitnami/keycloak/templates/statefulset.yaml#L284-L286)
* I couldn't just run `kc.sh export` as I had on the primary pod, but had to explicitly pass `--db`, `--db-username`, and `--db-password`. This is _probably_ self-evident if you understand the architecture of Keycloak, but wasn't obvious to me - the initial attempts to export from the main pod were failing because of a port clash, so "obviously" (scare-quotes because this is apparently wrong!) it was pulling data from some external datasource rather than from a local source.
* Since I was having the CronJob write out to an NFS-mounted volume (on my NAS), I needed to specify `securityContext.runAsUser` and `securityContext.fsGroup` on the `container`, and ensure that the corresponding values were set on the directory in the NAS's local filesystem, otherwise the CronJob would be denied write permission (thanks to [this SO question](https://stackoverflow.com/questions/50156124/kubernetes-nfs-persistent-volumes-permission-denied) for helping me figure this out - NFS permissions are beginning to make sense to me, but I'm still getting my head around it!)

My solution is [here](https://gitea.scubbo.org/scubbo/helm-charts/src/branch/main/app-of-apps/keycloak-backup.yaml). It's not perfect (I'd love to find a way to run `$(date +%s)` in the `args` to name the files according to date, and this setup breaks the neat "app-of-apps" setup I have going because this didn't seem deserving of a full Chart setup), but it works! It'd be really cool to contribute this to the [Bitnami Chart](https://github.com/bitnami/charts/tree/main/bitnami/keycloak) - I'm imagining a `backup` namespace in the `values.yaml` specifying schedule, persistent volume specs, and realms. Shouldn't be _too_ hard...
