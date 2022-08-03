---
title: "Self-Hosted Analytics"
date: 2022-08-02T20:23:48-07:00
tags:
  - homelab
  - meta

---
Way back in [this post]({{< ref "/posts/commenting-enabled" >}}), I talked about enabling Analytics Tracking on this blog. I disabled it a while back, as the move to an [actually self-hosted blog]({{<ref "/posts/self-hosting-blog" >}}) behind [Cloudflare Tunnels](https://www.cloudflare.com/products/tunnel/) (as opposed to an AWS-hosted one) messed that up a bit, and I was more incentivized to have a self-hosted blog without analytics, than vice versa. This post is the story of how I got self-hosting analytics working.
<!--more-->
(If you just want to jump down to the How To, click [here]({{< ref "#conclusion-and-next-steps" >}}))

## Evaluation of options

There are a _lot_ of Self-Hosted Analytics options out there - [Plausible](https://plausible.io/), [Umami](https://umami.is/), [Shynet](https://github.com/milesmcc/shynet), [Matomo](https://matomo.org/), the list goes on. I picked Plausible because of their focuses on:
* compliance - ain't nobody got time to implement GDPR for themselves, they want a ready-built solution (as my old colleagues on the Amazon Music Privacy & Compliance team knew all too well!)
* [privacy](https://plausible.io/privacy-focused-web-analytics), anti-capitalism ("_We're not interested in raising funds or taking investment. We choose the subscription business model rather than surveillance capitalism. We're operating a sustainable project funded solely by the fees that our subscribers pay us. And we donate 5% of our revenue._"), and environmentalism ("_A site with 10,000 monthly visitors can save 4.5 kg of CO2 emissions per year by switching._")
* lightweight simplicity

And, if I'm being honest, their website was way more impressive than the competition's, too!

## Getting it working

Despite being a primarily subscription-based service, Plausible went the extra mile by providing a [Github repo](https://github.com/plausible/hosting) dedicated to self-hosting, complete with a [docker-compose file](https://github.com/plausible/hosting/blob/master/docker-compose.yml) and [extra documentation](https://plausible.io/docs/self-hosting). Sweet! So I can just follow this guide and it will work?

Well, not quite. Plausible has a few dependencies - namely, [Bytemark](https://hub.docker.com/r/bytemark/smtp/) (a mail server), Postgres, and [Clickhouse](https://clickhouse.com/) (both databases - the former for configuration options, the latter for actual click/hit-tracking). Sadly, neither Plausible itself nor Bytemark have published images that work on arm64 (the architecture of Raspberries Pi), and the latest commits of Clickhouse and Plausible at the time of this experiment appeared to be broken, too. I am much indebted to Ștefan Stănciulescu who wrote a [great blog post](https://stefanstanciulescu.com/blog/plausible-analytics-on-raspberry-pi/) on their experience setting up Plausible on a Raspberry Pi, and who helpfully responded and updated their guidance after I reached out with more questions. After building Plausible (at commit `3242327d`) and Bytemark on ARM architecture, and pinning the Clickhouse image to tag `clickhouse-server:22.3.3-alpine`, I was able to get the Docker Compose solution working on a Raspberry Pi. Awesome!

## Getting it working on Kubernetes

But I'm ~~a sucker for punishment~~ always keen to push my learning further, so I wanted to get this working on Kubernetes. I faced a few challenges with this:

### Configuration upload

The docker-compose solution relies on mounting a couple of [configuration files](https://github.com/plausible/hosting/blob/master/docker-compose.yml#L20-L21) as "volumes". We can replicate this directly using a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/).

### Pre-chowning

On my first attempt, spin-up of the Postgres and Clickhouse containers would fail with an error message like `chown: changing ownership of '<path>': Operation not permitted`. Apparently NFS-provided volumes on Kubernetes have stricter permission control than local volumes provided by Docker(-compose).

Fortunately, this was an easy fix - [this SO answer](https://stackoverflow.com/questions/51200115/chown-changing-ownership-of-data-db-operation-not-permitted/51203031#51203031) suggested using an `initContainer` ([docs](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)) to pre-emptively `chown` the directory to the container's user before the container starts. This also seemed to require setting `no_root_squash` on the NFS export (previously I'd been using `all_squash`) - thanks to [this comment](https://github.com/kubernetes/kubernetes/issues/54601#issuecomment-346554420) for pointing that out.

### depends_on

Docker-compose has a neat feature called `depends_on` that lets you delay the start of one container until another container is ready and available, and this is used in [Plausible's docker-compose](https://github.com/plausible/hosting/blob/master/docker-compose.yml#L27-L34) to ensure that the main app doesn't start until the dependencies are ready. No such built-in feature exists in Kubernetes, but we can hack it in with another use of `initContainers`, since a pod's main `containers` will not start until all its `initContainers` have successfully completed. So, by creating two `initContainers` that will not successfully complete until Postgres/Clickhouse (respectively) are available, I can replicate this behaviour in Kubernetes.

I didn't bother implementing this for the `mail` container, since so far as I can tell I don't actually need it - Plausible uses email to go through the sign-up/forgot-password flow for users, but since there'll only be a single user of the app (me!) and I can (re)set my password manually with config options, I have intentionally left the `mail` container in an unconfigured (and probably non-functional) state.

### ulimits

The docker-compose file [sets some limits on the maximal number of open files](https://github.com/plausible/hosting/blob/master/docker-compose.yml#L22-L25), and from a quick skim of the [issue](https://github.com/kubernetes/kubernetes/issues/3595) it seems that this isn't implement in Kubernetes, so I just...ignored it :D in fairness, [this answer](https://serverfault.com/a/577441/151190) suggests that "_\[t\]here is almost no software in existence that can handle more than about 20,000 files open at a time_", and the limit in docker-compose was an order of magnitude higher than that, so probably functionally equivalent to an infinite limit.

### Service creation

In Docker-compose, every container is nicely addressable (to other containers) by the container name. In Kubernetes, it's not so simple, and you need to create a [Service](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#service-v1-core) to expose containers to one another (or the outside world). Even though I usually _hate_ video tutorials, [this guide](https://www.youtube.com/watch?v=fXQbkW1RNhE) was the best resource I found for grokking how they work. One really neat feature of Services that I had missed until now is that, if you create a service named `foo-service` in namespace `bar`, Kubernetes[^1] will set up the following DNS records within the cluster to resolve to that service:
* `foo-service` or `foo-service.svc.cluster.local`, for any resource[^2] in `bar` namespace
* `foo-service.bar` or `foo-service.bar.svc.cluster.local`, for any resource

Annoyingly, Plausible's [default configuration](https://github.com/plausible/analytics/blob/0324d03da98092dd586f0a9f39469f0a511e945c/config/runtime.exs#L56) assumes that the database is addressable at DNS name `plausible_db`, which is not a legal Kubernetes service name (underscores are forbidden), so I both had to create a service _and_ provide a configuration option telling Plausible where to find the database (and ditto for Clickhouse).

I ran into a _really_ confusing bug while setting this up, because I had foolishly configured both Pods (the dependencies - Bytemark, Postgres, and Clickhouse - and the Plausible pod itself) with identical labels, so the Service could not distinguish between them and, for reasons I don't fully understand, seemed to consistently prioritize the main-app pod (where no Postgres/Clickhouse containers were running). Once I figured out what was happening[^3], it was an easy fix to add distinguishing labels between the two pods and correctly direct the service.

### Email verification

By default, when you create a user in Plausible, you cannot log in as that user until the system has sent out a verification email and you've responded to it. [Ștefan](https://stefanstanciulescu.com/blog/plausible-analytics-on-raspberry-pi/) gave me a handy code snippet to bypass Email verification for all registered users of Plausible - `psql -U postgres -d plausible_db -c "UPDATE users SET email_verified = true;"`. This allows you to log in with username and password directly, without verification (and, so, this lets you run Plausible without a properly configured mail server).

Sadly, I haven't found a way to automate running this command during the Kubernetes deployment - it needs to be run _after_ the Plausible web app runs `/entrypoint.sh db init-admin` (otherwise no admin user will exist to be modified), but the Plausible web app image lacks `psql` or any other command-line Postgres interface, and Postgres doesn't have a built-in HTTP API[^4]. If I really wanted to I could probably modify the Plausible app image and add an `/entrypoint.sh db set-admin-email-verified` method using the Postgrex\[sic\] connector that the app uses - but I don't fancy learning a whole new framework (Phoenix) in a whole new language (Elixir) just for that. For now, I'm just running that single command once manually in the Kubernetes-provided shell in the Postgres container.

### Secrets

Lots of sensitive information - username, password, email, etc. - are encoded into the `plausible-env.conf`, which would have ended up as `env:` variables in YAML definition of pods. Even though my threat model shouldn't _seriously_ care too much about [attackers getting inside my home network](https://blog.scubbo.org/posts/secure-docker-registry/) (if that happens, I will have much bigger concerns than their access to my blog analytics!), I still wanted to learn the "proper" way to reference secret values.

Turns out this is super easy! A Secret in Kubernetes is a collection of key-value pairs, you can create it with `kubectl -n <namespace> create secret generic --from-file=key1=./path_to_file_containing_value_1 --from-file=key2=./path_to_file_containing_value_2` (remember to use `echo -n` to create the files, to prevent extra newlines being added), and secrets are referenced in env definitions of pods as:

```
env:
  - name: env_variable_name
    valueFrom:
      secretKeyRef:
        name: secret-name
        key: key
```

You can even [concatenate values](https://joeblogs.technology/2020/12/concatenating-kubernetes-secrets-for-environment-variables/), which came in handy when creating the connection string for the Postgres database (which includes the Postgres password)

### Cloudflared

It's no good _creating_ the Plausible app if blog-readers' browsers can't report to it! I've been using [Cloudflare Tunnels](https://www.cloudflare.com/products/tunnel/) to expose my services safely to the Internet (inspired by [this blog post](https://eevans.co/blog/garage/)). Recently, I'd [converted this Tunnel to also be run on Kubernetes](https://github.com/scubbo/pi-tools/commit/eeed75881dd1ceb4abdefb2852b4a7bc149be3bb) (previously, it was running as a `systemd` service), and working with this new service taught me an important gotcha - updating a ConfigMap does _not_ appear to force a refresh of the Pods in the Deployment, you will need to forcibly delete them so they will be recreated with the fresh configuration!

I haven't experimented enough to figure out whether I need to include logic in my Tunnel Containers to call `cloudflared tunnel route dns ...` to set up new DNS names, or if that will happen automagically with new config. That'll be another interesting thing to trip over in a later project!

## Conclusion and next steps

You can see the commit that introduced this application to my Kubernetes cluster [here](https://github.com/scubbo/pi-tools/commit/045e5dbb431c2c4c70b9eaeaa2445da192304a95); or, for a more user-friendly view, look at the directory [here](https://github.com/scubbo/pi-tools/tree/main/k8s-objects/plausible) which contains a `README.md`.

A lot of the issues that I tripped over when setting up Plausible on Kubernetes were either due to images not being available for ARM64, or due to my own lack of knowledge with Kubernetes. In hindsight, the whole process was pretty straightforward and simple.

Plausible also has a [drop-in page](https://plausible.io/docs/excluding-localstorage#allow-anyone-on-your-site-to-exclude-themselves) to let users opt-out of tracking - I've implemented it [here](/tracking_info). It does seem that Plausible does not respect the [Do Not Track header](https://www.eff.org/issues/do-not-track), though with [pretty justifiable reasons](https://github.com/plausible/analytics/discussions/646).

[^1]: Well, actually, "bare" Kubernetes will not do this by default, you need a DNS Add-on - but this apparently comes bundled by default with most Kubernetes installations, including [Rancher](https://rancher.com/products/rancher) which is what I'm currently using.
[^2]: I'm not sure if "resource" is the correct term to use, here. I know it's true for any Pod/Container, but I'm not sure if there are other types of resource that would care about DNS _other_ than those.
[^3]: which was harder than it sounded - as with many networking errors, "_unable to connect to_ `<correct_dns_name>`" doesn't tell you whether the issue is that the DNS name is misdirected, or that an issue exists on client _or_ server
[^4]: If either of these situation were different, I could either add another command into the `args` of the Plausible container, or make use of a [postStart lifecycle rule](https://stackoverflow.com/a/44146351/1040915)