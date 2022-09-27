---
title: "Grafana Oncall"
date: 2022-09-13T10:52:53-07:00
tags:
  - homelab
  - observability

---
I've had several instability issues with my Kubernetes cluster recently, and so I wanted to install some monitoring to
notify me of incipient issues. I'm already using [Grafana dashboards](https://grafana.com/grafana/) to visualize the
state of my cluster (using some of my own hand-crafted dashboards along with some
[pre-existing Kubernetes-specific ones](https://twitter.com/learn_cnative/status/1562847357032484865)), but that's only
useful if I happen to be looking at it at the time a problem is happening - it won't warn me of a brewing problem (and,
if the problem results in my VPN becoming unavailable while I'm away from home, that could result in complete
disconnection).
<!--more-->
Enter [OnCall](https://grafana.com/oss/oncall/), "_an open source, easy-to-use on-call management tool built to help
teams improve their collaboration and resolve incidents faster_". I'll only be using a miniscule slice of its
functionality - monitoring cluster health metrics, and notifying me if they start looking bad - but it's really cool to
see how Grafana is branching out and delivering awesome products in the Observability and
[Incident Management](https://grafana.com/blog/2022/09/13/grafana-incident-for-incident-management-is-now-generally-available-in-grafana-cloud/) spaces.

Unfortunately, although an arm64-compatible image of Grafana Oncall was
[made available a couple of weeks ago](https://github.com/grafana/oncall/issues/86), running OnCall on my Pi-hosted K3s
cluster wasn't as simple as the [instructions](https://github.com/grafana/oncall/tree/dev/helm/oncall) might have you
believe. Follow along as I show you the steps I went through.

Full disclosure, I'm _very_ new to Helm - OnCall's Helm chart is only the second chart I've worked with - so it's very possible that I've misunderstood some aspects or executed something non-idiomatically. Constructive criticism welcome!

## Summary of what I changed, added, or did differently or unexpectedly

* Explicitly split out the dependencies as advised by Helm chart comments.
* Personally built an arm64-compatible image of RabbitMQOperator, since I couldn't find one available in public repos.
* Served OnCall (and Grafana) over `http://` rather than `https://`, since I'm only exposing them within my own private network.
* Installed an Ingress for this installation manually, rather than using the built-in approach which clashes with k3s' built-in Traefik Ingress controller.


## Choices made during installation

### Independence of dependencies

The Grafana Helm chart advises [in](https://github.com/grafana/oncall/blob/7169b1b563af8596228cc50b07417c8dcc9c7293/helm/oncall/values.yaml#L79-L81)
[multiple](https://github.com/grafana/oncall/blob/7169b1b563af8596228cc50b07417c8dcc9c7293/helm/oncall/values.yaml#L108-L110)
[locations](https://github.com/grafana/oncall/blob/7169b1b563af8596228cc50b07417c8dcc9c7293/helm/oncall/values.yaml#L120-L121)
[to](https://github.com/grafana/oncall/blob/7169b1b563af8596228cc50b07417c8dcc9c7293/helm/oncall/values.yaml#L129-L130)
host the dependencies (MySQL, RabbitMQ, Redis, and Grafana itself) separately from the Helm-managed release. I'm curious
why that is the advice (that seems to run contrary to the value-add of Helm?) - but, I've done so.

### Namespacing

I've installed the OnCall components in the `grafana` namespace (where my existing Grafana installation exists), but it
should be pretty easy to change this to a different namespace if you want to, with some simple find-and-replaces. The
RabbitMQ Operator is installed to the built-in `kube-system` namespace,
"[_The namespace for objects created by the Kubernetes system_](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)",
which I haven't messed with.

## Pre-requisites

This guide assumes that you're running a [k3s](https://k3s.io/) Kubernetes cluster on 64-bit Raspberry Pis[^1], and that
you're familiar enough with Kubernetes to run `kubectl` commands against it. It also assumes that you have
[Helm](https://helm.sh/docs/intro/install/) installed and can run `helm` commands against your cluster.

It also assumes that you're already running your own Grafana instance. There are some
[example Kubernetes YAML files in this directory](https://github.com/scubbo/pi-tools/tree/main/k8s-objects/grafana)
if you want some guidance - it's a _lot_ simpler than OnCall, you shouldn't have too many problems!

{{< rawhtml >}}<a name="rabbitMQ"></a>{{< /rawhtml >}}Finally, there is no arm64-compatible RabbitMQ Operator available
([issue](https://github.com/rabbitmq/cluster-operator/issues/366)), so you will have to build your own:

```
$ git clone git@github.com:rabbitmq/cluster-operator.git
$ cd cluster-operator
$ sed -i'' 's/GOARCH=amd64/GOARCH=arm64/' Dockerfile
# Note - on Mac, you need a space between `-i` and `''`
#
# Build and push the image to your favourite Image Repository. E.g.:
$ docker build -t <your_registry_address>/rabbitmq/cluster-operator .
$ docker push <your_registry_address>/rabbitmq/cluster-operator
```
If you need guidance on setting up your own secure self-hosted Image Repository, check [here]({{< ref "/posts/secure-docker-registry" >}}).

## Installation

Locally clone my [`pi-tools` repo](https://github.com/scubbo/pi-tools), and navigate to `/k8s-objects/grafana/oncall`.

### MySQL

* Create a secret to hold the MySQL password by running, for example:
    `PASSWORD=$(date +%s | sha256sum | base64 | head -c 32); echo $PASSWORD; kubectl create secret -n grafana generic oncall-mysql-password --from-file=password=<(echo -n $PASSWORD)`
  * Note that `echo -n` is very important, otherwise the trailing newline will get included in the secret, and various
      systems are inconsistent in how they handle that. Don't run the risk of wasting several hours on this like I did!
* Prepare a Persistent Volume to hold the MySQL database. In my case, I've taken advantage of the fact that k3s has built-in support for NFS[^2] by declaring the PV [like so](https://github.com/scubbo/pi-tools/blob/main/k8s-objects/grafana/oncall/mysql.yaml#L70-L82), but you can adapt to whatever persistence system you prefer. Note that [since MySQL runs as userID `999`](https://github.com/docker-library/mysql/blob/master/8.0/Dockerfile.oracle#L11), the directory will have to be owned (or, at least, editable) by that user.
* Adapt `mysql.yaml` to match your PV, then apply it.

Note the use of `ConfigMap` to create a file (containing SQL) inside the directory `/docker-entrypoint-initdb.d` - a neat trick for initializing the database (as instructed by [the OnCall README](https://github.com/grafana/oncall/tree/dev/helm/oncall#connect-external-mysql))

If the MySQL instance had been created by use of the main OnCall Helm chart, you could specify the use of an arm64-compatible image by setting `mysql.image.repository` and `[...].tag` to the appropriate values.

### RabbitMQ

We will adapt the instructions [here](https://www.rabbitmq.com/kubernetes/operator/quickstart-operator.html) to install a RabbitMQ instance on your Kubernetes cluster, but using your [previously-built image](#rabbitMQ):

```
$ kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml"
$ kubectl set image -n rabbitmq-system deploy/rabbitmq-cluster-operator operator=<tag_of_your_image>
$ kubectl apply -f rabbitmq-cluster.yaml
```

Note that the tag needs to be accessible _by_ your Kubernetes cluster, so simply referring to a locally-tagged image on your development machine won't work - that is, the tag needs to include a registry hostname.

### Redis

...OK, I cheated a little. In my setup, this dependency _is_ handled by the Helm Chart, by setting values [like so](https://github.com/scubbo/pi-tools/blob/main/k8s-objects/grafana/oncall/values.yaml#L35-L41). This was primarily an experiment to see whether it was possible to set values in child charts (Redis is a child chart of OnCall [here](https://github.com/grafana/oncall/tree/dev/helm/oncall/charts), and the appropriate values are defined [here](https://github.com/bitnami/charts/blob/master/bitnami/redis/values.yaml#L69-L82)). If desired, I bet you could set up an independent Redis deployment following a similar path to the steps above.

### Values

Before installing oncall, go through `values.yaml` and make any necessary changes.

(Note that this discussion matches up to commit `939123` made on 2022-09-13 - if I've introduced any changes to the `values.yaml` since then that are not explained, feel free to reach out for clarification!)

* `base_url: oncall.grafana.avril` - this is the url on which your OnCall installation should be available. Your value will certainly be different from mine!
* `grafana.enabled: false` - if you wish to have the Helm chart create a Grafana installation alongside the OnCall installation (that is - if you're not hosting your own independent Grafana instance), set this to `true`. This will be a common pattern throughout the file
* `mysql.enabled: false` - as above
  * The docs [here](https://github.com/grafana/oncall/tree/dev/helm/oncall#connect-external-mysql) suggest that, instead, the value to be set is `mariadb.enabled`. That's surprising - MariaDB and MySQL appear to be different things - but, indeed, only `mariadb.enabled` [seems to be used throughout the codebase](https://github.com/grafana/oncall/search?q=mariadb.enabled), while [`mysql.enabled` is not](https://github.com/grafana/oncall/search?q=mysql.enabled). I suspect this is an old reference that was never cleaned up when a technology change happened? Regardless - I've set this value, even though it doesn't appear to be used, for forward-compatibility if it's ever re-introduced.
* `mariadb.enabled: false` - see above
* `externalMysql` - set values here to allow connection to your MySQL instance. If you've followed the instructions above, these shouldn't need to be changed.
  * Note that `password` is intentionally not set here - I wouldn't want to commit a sensitive value into a version-controlled file! Instead, a secret is identified when running the `helm install` command
* `rabbitmq.enabled: false` - see above
* `externalRabbitmq` - as with `externalMysql`
* `cert-manager.enabled: false` - it's pretty neat that OnCall's Helm chart includes integration with LetsEncrypt to automatically acquire TLS certificates for OnCall! However, this isn't relevant to my use-case - I don't need to expose my Grafana instance outside my home network, and doing so would be uselessly increasing my vulnerability surface, so a. there's no point in acquiring TLS certs, and b. even if I did, LetsEncrypt wouldn't be able to reach the server to confirm ownership.
* `oncall.slack.enabled: false` and `[...]telegram[...]` - at this stage, I don't actually have OnCall hooked up  _to_ anything.
* `ingress{,-nginx}.enabled: false` - OnCall's Helm chart can create an Ingress which allows a request to `base_url` to be redirected to the appropriate service/port combo. However, k3s comes with an Ingress controller called Traefik installed by default, and OnCall's attempted installation clashes with it: `0/3 nodes are available: 1 node(s) didn't have free ports for the requested pod ports. preemption: 0/3 nodes are available: 3 No preemption victims found for incoming pod.`. I disabled this and installed the Ingress manually (see [later section](#ingress))

### OnCall

Install the Grafana Helm chart repo:

```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

and install:

```
helm install -f values.yaml \
--set externalMysql.password=$(kubectl get secret -n grafana oncall-mysql-password --template={{.data.password}} | base64 --decode) \
--set externalRabbitmq.user=$(kubectl get secret -n grafana grafana-oncall-rabbitmq-cluster-default-user --template={{.data.username}} | base64 --decode) \
--set externalRabbitmq.password=$(kubectl get secret -n grafana grafana-oncall-rabbitmq-cluster-default-user --template={{.data.password}} | base64 --decode) \
oncall grafana/oncall
```

### Ingress

As described above, letting the OnCall Helm Chart install an Ingress results in a clash with the existing Traefik Ingress installation. Instead, I installed this Ingress manually: `kubectl apply -f ingress.yaml` (make sure to change the `rules[0].host` value to match `base_url` from your `values.yaml`. If we were installing this whole setup with a Helm chart, they could be linked by using Helm values - but, I want to better-understand why OnCall discourages installing dependencies via Helm before I Helm-ify this installation)

Note that we _could_ probably have let Helm install this Ingress, if there was an ability to set `ingressClassName` via Helm values [here](https://github.com/grafana/oncall/blob/7deb6fb9206f7372be36c7f0c1e06880dbe83772/helm/oncall/values.yaml#L53) (note that I _think_ this value is typo'd in the OnCall Helm chart - it should be `ingressClassName`, not `className`). In that case, we could set `ingressClassName: traefik`, and then everything should Just Work(tm). I'll follow up with the OnCall team to understand the motivation for keeping this commented out.

## Post-install setup

### Update DNS

Update your DNS provider so that the value of `base_url` points at your Kubernetes cluster. I haven't been able to find a good health-check url for OnCall (in particular, the [`README.md`](https://github.com/grafana/oncall/tree/dev/helm/oncall) and post-install output for the Helm chart suggests that `http://<base_url>/ready` should work, but that gives me a 404) - the best I've found is to just `curl <base_url>` and you should get back a payload reading `Ok`.

### Connect Grafana

Adapt the instructions in the `helm install` post-install output to install the OnCall plugin in your Grafana instance, and connect Grafana to the OnCall back-end:

* Get a one-time connection token: `kubectl exec -it $(kubectl get pods --namespace grafana -l "app.kubernetes.io/name=oncall,app.kubernetes.io/instance=oncall,app.kubernetes.io/component=engine" -o jsonpath="{.items[0].metadata.name}") -- bash -c "python manage.py issue_invite_for_the_frontend --override"`
  * Note that the original instructions appear to be incorrect - my pod had `app.kubernetes.io/instance=oncall`, not `...=release-oncall` as the output suggested.
* In the front-end for your Grafana instance, install the OnCall plugin, and fill in the connection token and the appropriate URLs for the back-end (this should be `<base_url>`, not `http://release-oncall-engine:8080` as the post-install output suggests)
  * If you skipped TLS certificates (like me), make sure to explicitly include the `http://` scheme in the url(s) - otherwise, you'll get a 502 error when the plugin tries to connect to the backend.

If the connection was successful, you should see output in the UI like:

```
Connected to OnCall (OpenSource, v1.0.32)
 - OnCall URL: http://<base_url>
 - Grafana URL: http://<your grafana url>>
```

## Next steps

I haven't actually set up any monitoring or notifications yet! The main monitor I want to set up is for low disk space on the nodes, as that seems to be the primary issue that I'm running into - but I'll look around for some suggestions of health metrics and share any good configurations that I find. Regarding notifications, I managed to get a [Matrix](https://matrix.org/) server running a few weeks back, and have made some decent progress on allowing bots to post to rooms - it would be really cool if I could contribute a Matrix integration to OnCall.

I'd also like to put in some alerting for if any CI/CD pipelines are blocked - in fact, what prompted this observability improvement in the first place was experimenting with a CI/CD step that would intentionally block publication of this blog if any pages contained the string [TK](https://en.wikipedia.org/wiki/To_come_(publishing)), and then realising that it wouldn't be great to have a pipeline that could be intentionally blocked without some notification of that fact.

I'd also like to build some iSCSI-based network storage, since I've heard that [hosting databases on NFS can be problematic](https://serverfault.com/a/789110).

I doubt that any of my issues will be significant enough that I'll need to start running [Grafana's Incident Management](https://grafana.com/blog/2022/09/13/grafana-incident-for-incident-management-is-now-generally-available-in-grafana-cloud/) locally - but it's nice to know that it exists if I want it!

## Questions

These are various things that I wasn't sure about, that I want to learn more about, or that I want to follow up on with the OnCall team:

* Why do comments in the Helm chart encourage the separate installation and management of dependencies, rather than using a single Helm installation?
* Why is `mariadb` used as a synonym for `MySql` in various places in the Helm chart?
* Is `kubectl get pods [...] -l "[...],app.kubernetes.io/instance=release-oncall` in the post-install instructions a typo? My installation resulted in `app.kubernetes.io/instance=oncall`, and I don't think I knowingly changed that.
* Why was [Ingress Class Name commented out](https://github.com/grafana/oncall/blob/7deb6fb9206f7372be36c7f0c1e06880dbe83772/helm/oncall/values.yaml#L53)? (or - would you accept a PR to make this configurable?)
* Is there a good health check URL for OnCall (`/ready` doesn't work, despite post-install instructions), or is it just `/`?
* (A question for myself, rather than the OnCall team) _Does_ k3s come with NFS enabled by-default, or did I install something to enable it - and, if so, what?

**EDIT:** A friend let me know that setting an annotation of `kubernetes.io/ingress.class` is equivalent to setting an `ingressClassName` - and, indeed, by manually setting that annotation in my yaml:
```yaml
ingress:
  enabled: true
  annotations:
    "kubernetes.io/ingress.class": "traefik"
```
I was able to get a working (Traefik) Ingress created with the Oncall Helm chart. It appears that the Helm chart
[_should_](https://github.com/grafana/oncall/blob/7deb6fb9206f7372be36c7f0c1e06880dbe83772/helm/oncall/templates/ingress-regular.yaml#L4-L8)
take the `ingress.className` value and insert it as this annotation - but this is flawed for 2 reasons:
* It relies on `.Capabilities.KubeVersion.GitVersion`, which is [deprecated in Helm 3.x](https://github.com/helm/charts/issues/20918). I'm not sure whether this is actually causing any problems for me, since my k3s version is `v1.24.3+k3s1` (i.e. `>=1.18`, so you wouldn't expect this annotation-addition to execute in my environment anyway), but it's probably something that should be checked. I know it's unlikely that anyone will have a modern (>3.x) Helm version and an old (<1.18) version of Kubernetes, but the Oncall team might want to check it out.
* The annotation-based approach of defining Ingress class is [deprecated as of Kubernetes v1.18](https://kubernetes.io/docs/concepts/services-networking/ingress/#deprecated-annotation), which is presumably why the annotation-based approach gates on Kubernetes version `<1.18` - but there's no corresponding `if version >= 1.18` logic in the template to set the `ingressClassName` property.

To that end, I've created [this PR](https://github.com/grafana/oncall/pull/567) on the Oncall repo with what I believe is the fix.


[^1]: I'm not aware of distinctions between Pi models that would have any effect here; but, for the record, my cluster is 3\*Pi4s.
[^2]: I'm a little confused by this statement, actually; since both [a friend who is more-experienced Kubernetes-wrangler](https://twitter.com/cloudycelt), and a [recent article](https://www.phillipsj.net/posts/k3s-enable-nfs-storage/), suggest that this is not the case. What can I say: [it works for me](https://github.com/scubbo/pi-tools/search?q=%22server%3A+rassigma.avril%22), and I don't recall installing anything special? If you are following these instructions and run into issues, please do let me know so that we can try to reverse-engineer whatever I did to make this work!
