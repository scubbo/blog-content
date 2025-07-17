---
title: "Authentication in the New World"
date: 2025-07-16T22:30:17-07:00
tags:
  - CI/CD
  - Homelab
  - Meta
  - Starting-Over
  - Vault

---
Contrary to my hopes in the [previous post]({{< ref "/posts/a-new-start" >}}), Vault did _not_ magically come back up again. I'm not sure why, but the ZVols created on TrueNAS by the previous cluster had truly gone away: thanks to `zfs get`, I could see that the creation times of all iSCSI ZVols was in the last week or so, i.e. while I've been rebuilding, not from the previous cluster. I guess when the StorageClass was deleted, it also wiped out all associated ZVols? That doesn't quite ring true to me, as the cluster _itself_ was inoperable due to unavailability of the Cluster Config (which was stored on an NFS mount on the drive that failed) - but, eh, can't argue with results. The data was gone[^recovery], so, time to rebuild!
<!--more-->
I [documented the process a little better this time around](https://github.com/scubbo/homelab-configuration/blob/main/charts/vault/README.md). Installation of the [GitHub token](https://github.com/martinbaillie/vault-plugin-secrets-github) was pretty smooth, though I did hit a new roadblock - since I'm using GitHub rather than self-hosted Gitea, the runners don't have access to Vault (I don't trust my security well enough to expose Vault to the public Internet!), so I had to set up a self-hosted runner to run the jobs.

Naturally I tried the [Helm-based approach](https://docs.github.com/en/actions/tutorials/actions-runner-controller/quickstart-for-actions-runner-controller) first, but got an error while test-installing it (i.e. not from IaC):

```
$ helm install arc --namespace arc-systems --create-namespace oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
Error: INSTALLATION FAILED: GET "https://ghcr.io/v2/actions/actions-runner-controller-charts/gha-runner-scale-set-controller/tags/list": GET "https://ghcr.io/token?scope=repository%3Aactions%2Factions-runner-controller-charts%2Fgha-runner-scale-set-controller%3Apull&service=ghcr.io": unexpected status code 403: denied: denied
```

And, to be honest - it's nearly 11pm, I'm tired, and the fact that that's the first `oci://`-based Helm chart that I've encountered means I really don't want to try debugging that right now; I need a win!

So I adapted the instructions from [here](https://docs.github.com/en/actions/how-tos/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners#adding-a-self-hosted-runner-to-a-repository) and [here](https://testdriven.io/blog/github-actions-docker/) to make a `Dockerfile` and `./start.sh` that I could dump onto one of the bare nodes:

```Dockerfile
# Dockerfile

# Note I had to use a more-modern Ubuntu version than the example, due to
# https://old.reddit.com/r/linux4noobs/comments/1crp9f4/node_libx86_64linuxgnulibcso6_version_glibc_228/
FROM ubuntu:20.04

ARG RUNNER_VERSION="2.326.0"

RUN apt-get update -y && apt-get upgrade -y && useradd -m docker
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Must install tzdata in a special way to make it noninteractive
# https://serverfault.com/a/992421
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata

RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

# We need git for the actual operation of the workflow!
# `apt-get install git` from within the workflow gives a permission error - which I guess is expected as it's running
# as `docker`, not `root`
RUN apt-get install -y git

COPY start.sh start.sh
RUN chmod +x start.sh


USER docker
ENTRYPOINT ["./start.sh"]
```

```bash
# start.sh
#!/bin/bash

cd /home/docker/actions-runner

./config.sh --url https://github.com/scubbo/blog-content --token <my_token>

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token <my_token>
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
```
, ran it with `docker run $(docker build -q .) --network host --name actions_runner`, and it seems to be working. At least - if this is published, you'll know it is!

[^recovery]: There are some pretty dedicated folks [here](https://github.com/democratic-csi/democratic-csi/issues/20) and [here](https://github.com/democratic-csi/democratic-csi/issues/273) with some tales of recovery data from ZVols ffrom a _running_ cluster, which...is a little odd to me. If the cluster's running, why do you need a recovery process, why can't you just...access the data? Regardless - maybe they'll be helpful to someone else!
