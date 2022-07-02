---
title: "Secure Docker Registry"
date: 2022-07-01T21:26:32-07:00
tags:
  - homelab
---
Part of the self-hosted setup that supports this blog (along with all my other homelab projects) is a [Docker Registry](https://docs.docker.com/registry/) to hold the images built and used in the CI/CD pipeline. Recently I tried to install TLS certificates to secure interaction with the Registry, and it was a fair bit harder to figure out than I expected, so I wanted to write it up both for future-me and for anyone else struggling with the same problem.
<!--more-->
(To be clear, this was almost entirely unnecessary. The registry will never be exposed outside my own private network, so security measures are _basically_ unnecessary as a threat model that includes attackers getting inside the network probably has bigger things to worry about than intercepting the image registry. But _most_ of my homelab work is impractical and done only for satisfaction and learning, so why should this be any different?)

There were four steps to getting this working - creating the certificates themselves, enabling their use in the registry, enabling secure upload _to_ the registry, and enabling secure download _from_ it.

## Creating certificates

The [EFF](https://www.eff.org/) provide a great tool called [certbot](https://certbot.eff.org/) for creating TLS certs for an existing site. It requires temporarily exposing the site to the public internet on ports 80 and 443, but since Kubernetes seems to take over those ports on any node, I worked around that by forwarding the standard ports to arbitrary ports on the target machine, then mapping those arbitrary ports back to the standard ports in the `docker` command for certbot.

The command to create the certs was:

```
$ sudo docker run -it --rm --name certbot \
    -v "/etc/letsencrypt:/etc/letsencrypt" \
    -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
    -p <arbitrary_port_1>:80 -p <arbitrary_port_2>:443 \
    certbot/certbot:arm64v8-latest certonly \
    --standalone -d <domain_name> \
    -m <email_address> --agree-tos -n
```

(There's rate-limiting applied on all requests, even those that fail, so you should run this with `--test-cert` until you get a working setup)

Assuming everything works correctly, this will create certs for your domain name under `/etc/letsencrypt/live/<domain_name>`. They'll all be `.pem` files, named `cert`, `chain`, `fullchain`, and `privkey`. These aren't the names commonly used in other settings, so you can map between them as follows:
* `cert.pem` is often referred to as `client.cert`.
* `privkey.pem` -> `client.key`.
* `chain.pem` or `fullchain.pem` -> `<domain_name>.crt` - I'm not currently clear on the difference between these files, but `chain.pem` seems to work fine.

## Enabling secure access to registry

There are a [few extra arguments](https://docs.docker.com/registry/deploying/#run-an-externally-accessible-registry) to pass to the Docker Registry run command:

```
$ docker run -d \
  --restart=always \
  --name registry \
  -v <path_to_dir_containing_certs>:/certs \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -p 443:443 \
  registry:2
```

(Note, again, the inconsistency in naming! The argument to `REGISTRY_HTTP_TLS_CERTIFICATE` should be the `chain.pem` file from `certbot`, and likewise the argument to `REGISTRY_HTTP_TLS_KEY` should be the `privkey.pem` file)

## Enabling secure upload

I'm using [Drone](https://www.drone.io/) to trigger builds upon pushing a change to a Git repo. I [had some trouble](https://stackoverflow.com/questions/72823418/how-to-make-drone-docker-plugin-use-self-signed-certs) getting the Drone runner to use the certs - for reasons I still don't understand, mounting a directory containing the certificates and then copying the certificates into the correct place didn't work, but mounting the certificate files directly works fine.

My Drone Runner command is:

```
$ docker run \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
    --env=DRONE_RPC_PROTO=http \
    --env=DRONE_RPC_HOST=<host:port_of_drone_server> \
    --env=DRONE_RPC_SECRET=<drone_rpc_secret> \
    --env=DRONE_RUNNER_CAPACITY=2 \
    --env=DRONE_RUNNER_NAME=drone-runner \
    --env=DRONE_RUNNER_VOLUMES=/var/run/docker.sock:/var/run/docker.sock,$(readlink -f <path_to_chain.pem>):/registry_cert.crt \
    --publish=3502:3000 \
    --restart=always \
    --detach=true \
    --name=runner \
    drone/drone-runner-docker:1
```

Some notes on this:
* Using `readlink -f` traverses symlinks to the eventual target file - otherwise, the file mounted into the runner container would be a symlink pointing to an absent file
* `DRONE_RUNNER_CAPACITY` is arbitrary - as many as you need (and your node will support!)
* I don't _think_ that it's actually necessary to publish any ports from the runner, since runners reach out to the server to register and do not need to accept any incoming requests

With the runner set up like so, the `.drone.yml` file to define the workflow should look like:

```
kind: pipeline
name: <name_of_workflow>
type: docker

platform:
  os: linux
  arch: arm64 # Architecture of Raspberries Pi - your case might be different!

steps:
  - name: copy-cert-into-place
    image: busybox
    volumes:
      - name: docker-cert-persistence
        path: /etc/docker/certs.d/
    commands:
      # https://stackoverflow.com/questions/72823418/how-to-make-drone-docker-plugin-use-self-signed-certs
      - mkdir -p /etc/docker/certs.d/<domain_name:port>
      - cp /registry_cert.crt /etc/docker/certs.d/<domain_name:port>/ca.crt
  <Add a step - or several! - here building your image>
  - name: push-built-image
    image: plugins/docker
    volumes:
      - name: docker-cert-persistence
        path: /etc/docker/certs.d/
    settings:
      repo: <domain_name:port>/<image_name>
      tags: <tag>
```

Note that the directory name where the certs are copied to must match the domain name and port where the registry will be accessed, as per the [documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#insecure-registries): "_A secure registry uses TLS and a copy of its CA certificate is placed on the Docker host at_ `/etc/docker/certs.d/myregistry:5000/ca.crt`" (note that `5000` is the standard port docker registries, but you can expose it on whatever port you want!)

If you want to double-check that your certificates work correctly, you can add a step after `copy-cert-into-place` like so:

```
- name: check-cert-persists-between-stages
  image: alpine
  volumes:
    - name: docker-cert-persistence
      path: /etc/docker/certs.d/
  commands:
    - apk add curl
    - curl https://<domain_name:port>/v2/_catalog --cacert /etc/docker/certs.d/<domain_name:port>/ca.crt
```

## Enabling secure download

I'm using a [Rancher](https://rancher.com/products/rancher) Kubernetes cluster to run my containers, which operates slightly differently from standard Kubernetes - according to [this conversation](https://github.com/kubernetes/kubernetes/issues/43924) (with a..._heated_ [comment](https://github.com/kubernetes/kubernetes/issues/43924#issuecomment-296578318) ;) ), standard Kubernetes just requires that the certificates are installed to the standard locations of `/etc/docker/certs.d/` and the output of `update-ca-certificates`. However, for Rancher, the mapping is more explicit - in the [`registries.yaml`](https://rancher.com/docs/k3s/latest/en/installation/private-registry/) file, you can define the `cert_file` (`cert.pem/client.cert`), `key_file` (`privkey.pem/client.key`), and `ca_file` (`chain.pem/<domain>.crt`)

This was frustratingly hard to discover, since searching for "Rancher CA Cert" tended to produce results for installing a self-hosted certificate for _calling_ the Kubernetes Ingresses, rather than for Kubernetes calling a registry

Put that all together, and you should have a secure Docker registry that your Drone CI/CD pipeline and Kubernetes cluster can push to and pull from!
