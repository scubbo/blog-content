---
title: "Vault Secrets Into K8s"
date: 2024-04-21T19:51:06-07:00
tags:
  - homelab
  - k8s
  - vault

---
Continuing my [recent efforts]({{< ref "/posts/oidc-on-k8s" >}}) to make authentication on my homelab cluster more "joined-up" and automated, this weekend I dug into linking Vault to Kubernetes so that pods could authenticate via shared secrets without me having to manually create the secrets in Kubernetes.
<!--more-->
As a concrete use-case - currently, in order for Drone (my CI system) to authenticate to Gitea (to be able to read repos), it needs OAuth credentials to connect. These are provided to Drone in [env variables, which are themselves sourced from a secret](https://gitea.scubbo.org/scubbo/helm-charts/src/commit/1926560274932d4cd052d2281cac82d4f33cacd3/charts/drone/values.yaml#L8-L9). In an ideal world, I'd be able to configure the applications so that:
* When Gitea starts up, if there is no OAuth app configured for Drone (i.e. if this is a cold-start situation), it creates one and writes-out the creds to a Vault location.
* The values from Vault are injected into the Drone namespace.
* The Drone application picks up the values and uses the to authenticate to Gitea.

I haven't taken a stab at the first part (automatically creating a OAuth app at Gitea startup and exporting to Vault), but injecting the secrets ended up being pretty easy!

# Secret Injection

There are actually three different ways of providing Vault secrets to Kubernetes containers:

* The [Vault Secrets Operator](https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator), which syncs Vault Secrets to Kubernetes Secrets.
* The [Vault Agent Injector](https://developer.hashicorp.com/vault/docs/platform/k8s/injector), which syncs Vault Secrets to mounted paths on containers.
* The [Vault Proxy](https://developer.hashicorp.com/vault/docs/agent-and-proxy/proxy), which can act as a (runtime) proxy to Vault for k8s containers, simplifying the process of authentication[^provision].

I don't _think_ that Drone's able to load OAuth secrets from the filesystem or at runtime, so Secrets Operator it is!

![Vault Secrets operator](https://developer.hashicorp.com/_next/image?url=https%3A%2F%2Fcontent.hashicorp.com%2Fapi%2Fassets%3Fproduct%3Dtutorials%26version%3Dmain%26asset%3Dpublic%252Fimg%252Fvault%252Fkubernetes%252Fdiagram-secrets-operator.png%26width%3D321%26height%3D281&w=750&q=75 "Diagram of Vault Secrets Operator injection process")

The walkthrough [here](https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator) was very straightforward - I got through to creating and referencing a Static Secret with no problems, and then tore it down and recreated via [IaC](https://gitea.scubbo.org/scubbo/helm-charts/commit/b856fd2bc5dd047ca93809bd102315cf867740d3). With that in place, it was pretty easy to (convert my [Drone specification to jsonnnet](https://gitea.scubbo.org/scubbo/helm-charts/commit/1926560274932d4cd052d2281cac82d4f33cacd3) and then to) [create a Kubernetes secret referencing the Vault secrets](https://gitea.scubbo.org/scubbo/helm-charts/commit/4c82c014f83020bad95cb81bc34767fef2c232c1). I deleted the original (manually-created) secret and deleted the Drone Pod immediately before doing so just to check that it worked - as I expected, the Pod failed to come up at first (because the Secret couldn't be found), and then successfully started once the Secret was created. Works like a charm!

## (Added 2024-04-29) Namespacing secrets

After attempting to use these Secrets for another use-case, I've run into a speed-bump: the `bound_service_account_namespaces` for the Vault role specifies which Kubernetes namespaces can use that Role to access secrets, but it's all-or-nothing - if a role is available to multiple namespaces, there's no way to restrict that a given namespace can only access certain secrets.

I haven't seen this explicitly stated, but it seems like the intended way to control access is to, create a different Vault Role for each namespace (only accessible _from_ that namespace), and to grant that Vault Role only the appropriate Vault policies.

Gee, if [only](https://www.crossplane.io/) there was a way to manage Vault entities via Kubernetes...😉

# Further thoughts

## Type-safety and tooling

I glossed over a few false starts and speedbumps I faced with typoing configuration values - `adddress` instead of `address`, for instance. I've been tinkering with [`cdk8s`](https://cdk8s.io/) at work, and really enjoy the fact that it provides Intellisense for "type-safe" configuration values, prompting for expected keys and warning when unrecognized keys are provided. Jsonnet has been a great tool for factoring out commonalities in application definitions, but I think I'm overdue for adopting `cdk8s` at home as well! (And, of course, using [Crossplane](http://crossplane.io/) to define the initial Vault bootstrapping required (e.g. the `/kubernetes` auth mount) would fully automate the disaster-recovery case)

Similarly, it's a little awkward that the Secret created is part of the `app-of-apps` application, rather than the `drone` application. I structured it this way (with the Vault CRDs at the top-level) so that I could extract the `VaultAuth` and `VaultStaticSecret` to a Jsonnet definition so that they could be reused in other applications. If I'd put the auth and secret definition _inside_ the `charts/drone` specficiation, I'd have had to figure out how to create and publish a [Helm Library](https://helm.sh/docs/topics/library_charts/) to extract them. Which, sure, would be a useful skill to learn - but, one thing at a time!

## Dynamic Secrets

I was partially prompted to investigate this because of a similar issue we'd faced at work - however, in that case, the authentication secrets are dynamically-generated and short-lived, and client apps will have to refetch auth tokens periodically. It looks like the Secrets Operator also supports [Dynamic Secrets](https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator#dynamic-secrets), whose "_lifecycle is managed by Vault and \[which\] will be automatically rotated_". This isn't _quite_ the situation we have at work - where, instead, a fresh short-lived token is created via a Vault Plugin on _every_ secret-read - but it's close! I'd be curious to see how the Secrets Operator can handle this use-case - particularly, whether the environment variable _on the container itself_ will be updated when the secret is changed.

### Immutable Secrets - what's in a name?

There's a broader question, here, about whether the value of secrets should be immutable over the lifespan of a container. [Google's Container Best Practices](https://cloud.google.com/architecture/best-practices-for-operating-containers#immutability)[^best-practices] suggest that "_a container won't be modified during its life: no updates, no patches, no configuration changes.[...]If you need to update a configuration, deploy a new container (based on the same image), with the updated configuration._". Seems pretty clear cut, right?

Well, not really. What _is_ the configuration value in question, here? Is it the actual token which is used to authenticate, or is it the Secret-store path at which that token can be found?

* If the former, then when the token rotates, the configuration value has been changed, and so a new container should be started.
* If the latter, then a token rotation doesn't invalidate the configuration value (the path). The application on the container can keep running - but will have to carry out some logic to refresh its (in-memory) view of the token.

When you start to look at it like that, there's plenty of precedent for "higher-level" configuration values, which are interpreted at runtime to derive more-primitive configuration values:
* Is the config value "_how long you should wait between retries_", or "_the rate at which you should backoff retries_"?
* Is it "_the colour that a button should be_", or "_the name of the A/B test that provides the treatments for customer-to-colour mappings_"?
* Is it "_the number of instances that should exist_", or "_the maximal per-instance memory usage that an auto-scaling group should aim to preserve_"?

Configuration systems that allow the behaviour of a system to change at runtime (either automatically in response to detected signals, or as induced by deliberate human operator action) provide greater flexibility and functionality. This fuctionality - which is often implemented by designing an application to regularly poll an external config (or secret) store for the more-primitive values, rather than to load them once at application startup - comes at the cost of greater tooling requirement for some desirable operational properties:

* **Testing:** If configuration-primitives are directly stored-by-value in Git repos[^secrets-in-code] and a deployment pipeline sequentially deploys them, then automated tests can be executed in earlier stages to provide confidence in correct operation before promotion to later ones. If an environment's configuration can be changed at runtime, there's no guarantee (unless the runtime-configuration system provides it) that that configuration has been tested.
* **Reproducibility:** If you want to set up a system that almost-perfectly[^almost-perfect-reproduction] reproduces an existing one, you need to know the configuration values that were in place at the time. Since time is a factor (you're always trying to reproduce a system that _existed at some time in the past_, even if that's only a few minutes prior), if runtime-variable and/or pointer-based configurations are effect, you need to refer to an audit log to know the actual primitives in effect _at that time_.

These are certainly trade-offs! As with any interesting question, the answer is - "_it depends_". It's certainly the case that directly specifying primitive configuration is _simpler_ - it "just works" with a lot of existing tooling, and generally leads to safer and more deterministic deployments. But it also means that there's a longer reflection time (time between "_recording the desire for a change in behaviour in the controlling system_" and "_the changed behaviour taking effect_"), because the change has to proceed through the whole deployment process[^deployment-process]. This can be unacceptable for certain use-cases:
* operational controls intended to respond in an emergency to preserve some (possibly-degraded) functionality rather than total failure.
* updates to A/B testing or feature flags.
* (Our original use-case) when an authentication secret expires, it would be unacceptable for a service that depends on that secret to be nonfunctional until configuration is updated with a new secret value[^overlap]. Much better, in this case, for the application _itself_ to refresh its own in-memory view of the token with a refreshed one. So, in this case, I claim that it's preferable to treat "_the path at which an authentication secret can be found_" as the immutable configuration value, rather than "_the authentication secret_" - or, conversely, to invert responsibility from "_the application is told what secret to use_" to "_the application is responsible for fetching (and refreshing) secrets from a(n immutable-over-the-course-of-a-container's-lifecycle) location that it is told_"

To be clear, though, I'm only talking here about authentication secrets that have a specified (and short - less than a day or so) Time-To-Live; those which are intended to be created, used, and abandoned rather than persisted. Longer-lived secrets should of course make use of the simpler and more straightforward direct-injection techniques.

### What is a version?

An insightful coworker of mine recently made the point that configuration should be considered an integral part of the deployed version of an application. That is - it's not sufficient to say "_Image tag `v1.3.5` is running on Prod_", as a full specification should also include an identification of the config values in play. When investigating or reasoning about software systems, we care about the overall behaviour, which arises from the intersection of code _and_ configuration[^and-dependencies], not from code alone. The solution we've decided on is to represent an "application-snapshot" as a string of the form `"<tag>:<hash>"`, where `<tag>` is the Docker image tag and `<hash>` is a hash of the configuration variables that configure the application's behaviour[^configuration-index].

Note that this approach is not incompatible with the ability to update configuration values at runtime! We merely need to take an outcome-oriented view - thinking about what we want to achieve or make possible. In this case, we want an operator investigating an issue to be prompted to consider proximate configuration changes if they are a likely cause of the issue.

* Is the configuration primitive one which naturally varies (usually within a small number/range of values) during the normal course of operation? Is it a "tuning variable" rather than one which switches between meaningfully-different behaviours? Then, do not include it as a member of the hash. It is just noise which will distract rather than being likely to point to a cause - a dashboard which records multiple version updates every minute is barely more useful than one which does not report any.
  * Though, by all means log the change to your observability platform! Just don't pollute the valuable low-cardinality "application version" concept with it.
* Is the configuration primitive one which changes rarely, and/or which switches between different behaviours? Then, when it is changed (either automatically as a response to signals or system state; or by direct human intervention), recalculate the `<hash>` value and update it _while the container continues running_[^does-datadog-support-this].

[^provision]: Arguably this isn't "_a way of providing secrets to containers_" but is rather "_a way to make it easier for containers to fetch secrets_" - a distinction which actually becomes relevant [later in this post](#immutable-secrets---whats-in-a-name)...
[^best-practices]: And by describing _why_ that's valuable - "_Immutability makes deployments safer and more repeatable. If you need to roll back, you simply redeploy the old image._" - they avoid the [cardinal sin](https://domk.website/blog/2021-01-31-cult-of-best-practise.html) of simply asserting a Best Practice without justification, which prevents listeners from either learning how to reason for themselves, or from judging whether those justifications apply in a novel and unforeseen situation.
[^secrets-in-code]: which is only practical for non-secret values _anyway_ - so we must _always_ use some "pointer" system to inject secrets into applications.
[^almost-perfect-reproduction]: You almost-never want to _perfectly_ reproduce another environment of a system when testing or debugging, because the I/O of the environment is part of its configuration. That is - if you perfectly reproduced the Prod Environment, your reproduction would be taking Production traffic, and would write to the Production database! This point isn't just pedantry - it's helpful to explicitly list (and minimize) the _meaningful_ ways in which you want your near-reproduction to differ (e.g. you probably want the ability to attach a debugger and turn on debug logging, which should be disabled in Prod!), so that you can check that list for possible explanations if _your_ env cannot reproduce behaviour observed in the original. Anyone who's worked on HTTP/S bugs will know what I mean...
[^deployment-process]: where the term "deployment process" could mean anything from "_starting up a new container with the new primitive values_" (the so-called "hotfix in Prod"), to "_promoting a configuration change through the deployment pipeline_", to "_building a new image with different configuration 'baked-in' and then promoting etc...._", depending on the config injection location and the degree of deployment safety enforcement. In any case - certainly seconds, probably minutes, potentially double-digit minutes.
[^overlap]: An alternative, if the infrastructure allowed it, would be an "overlapping rotation" solution, where the following sequence of events occurs: 1. A second version of the secret is created. Both `secret-version-1` and `secret-version-2` are valid. 2. All consumers of the secret are updated to `secret-version-2`. This update is reported back to the secret management system, which waits for confirmation (or times out) before proceeding to... 3. `secret-version-1` is invalidated, and only `secret-version-2` is valid. Under such a system, we could have our cake and eat it, too - secrets could be immutable over the lifetime of a container, _and_ there would be no downtime for users of the secret. I'm not aware of any built-in way of implementing this kind of overlapping rotation with Vault/k8s - and, indeed, at first thought the "callbacks" seem to be a higher degree of coupling than seems usual in k8s designs, where resources generally don't "know about" their consumers.
[^and-dependencies]: Every so often I get stuck in the definitional and philosophical rabbit-hole of wondering whether this is _entirely_ true, or if there's a missing third aspect - "_behaviour/data of dependencies_". If Service A depends on Service B (or an external database), then as Service B's behaviour changes (or the data in the database changes), then a given request to Service A may receive a different response. Is "the behaviour" of a system defined purely in terms of "_for a given request, the response should be (exactly and explicitly) as follows..._", or should the behaviour be a function of both request _and_ dependency-responses? The answer - again, as always - is "it depends': each perspective will be useful at different times and for different purposes. Now that you're aware of them both, though, be wary of misunderstandings when two people are making different assumptions!
[^configuration-index]: which requires an enumeration of said variables to exist in order to iterate over them. Which is a good thing to exist anyway, so that a developer or operator knows all the levers they have available to them, and (hopefully!) has some documentation of their [intended and expected effects](https://brooker.co.za/blog/2020/06/23/code.html).
[^does-datadog-support-this]: I should acknowledge that I haven't yet confirmed that work's observability platform actually supports this. It would be a shame if they didn't - a small-minded insistence that "_configuration values should remain constant over the lifetime of a container_" would neglect to acknowledge the practicality of real-world usecases.

<!--
Reminders of patterns you often forget:

Images:
![Alt-text](url "Caption")

Internal links:
[Link-text](\{\{< ref "/posts/name-of-post" >}})
(remove the slashes - this is so that the commented-out content will not prevent a built while editing)
-->