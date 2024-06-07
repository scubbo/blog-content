---
title: "Auto Announce on Mastodon"
date: 2024-06-07T13:46:00+00:00
tags:
  - CI/CD
  - homelab
  - meta
  - vault

---
I just set up a step in my publication pipeline to automatically post on Mastodon when I publish a new blog post.
<!--more-->
The Mastodon API for posting is pretty easy, per [this guide](https://dev.to/bitsrfr/getting-started-with-the-mastodon-api-41jj). I grabbed a Mastodon token and put it into Vault to be accesible (as detailed in [previous]({{< ref "/posts/vault-secrets-into-k8s" >}}) [posts]({{< ref "/posts/base-app-infrastructure" >}})) to the CD pipeline.

Accessing Kubernetes secrets in Drone pipelines required installing the [Kubernetes Secrets Extension](https://docs.drone.io/runner/extensions/kube/)[^can-access-directly], which was [fairly easy](https://gitea.scubbo.org/scubbo/helm-charts/commit/8d70bbe78b1e818906a43913f489c120446c2276)[^sketchy-documentation]. I [already had Vault->Kubernetes Secret integration set up](https://gitea.scubbo.org/scubbo/helm-charts/commit/4c82c014f83020bad95cb81bc34767fef2c232c1), so plumbing the secret in was [also easy](https://gitea.scubbo.org/scubbo/helm-charts/commit/4cc1c531e270e6fbfd2af0219a0bf2eaa799a75c). I did run into a bit of confusion in that there's no mention in Drone docs of how to specify a non-`default` namespace from which to fetch Kubernetes secrets - turns out there are [two](https://github.com/drone/charts/blob/master/charts/drone-kubernetes-secrets/values.yaml#L74) [places](https://github.com/drone/charts/blob/master/charts/drone-kubernetes-secrets/values.yaml#L93) that need to be set to that value, not just one.

With all the pieces assembled, I just needed to write some hacky Bash (is there any other kind!?) to check for commits that are creating a new file in the `blog/content/posts/` directory (I don't want to "announce" commits that are only updates, or that are changing the system rather than the content), and let 'er rip. As a next step, it would be nice to extract this logic to a standalone image[^auto-update] for others to use as a Drone plugin - though my use-case is probably specific enough that this wouldn't be valuable. If you'd like it, though, let me know!

(I'm still not 100% sure that my [step to clear the cache on my main blog page](https://gitea.scubbo.org/scubbo/blogcontent/src/commit/58db334e96444d8768abe62bf42256a5b722efdc/.drone.yml#L117-L123) is working as expected - if you see unexpected behaviour that could be due to old cached values, please let me know!)

# My evolving views on CI/CD

During the process of implementing this change, I came to some realizations about the design and motivation of CI/CD systems.

I'm [pretty strongly on-the-record]({{< ref "/posts/ci-cd-cd, oh my" >}}) as believing that Amazon's internal Pipelines tool is one of the best things about developing there, and my opinion on that has only grown stronger with time (especially if you extend it to the dependency-version-management system, which almost entirely negates [Dependency Hell](https://en.wikipedia.org/wiki/Dependency_hell)). I was pretty surprised to get some [pushback](https://x.com/ZiggyTheHamster/status/1577076232243380230) on that from an ex-colleague when I first stated that position - he was extremely dissatisfied with Pipelines, in ways that made no sense to me. Nearly two years later, I think I've reached some better understanding - and, unsurprisingly, the disagreement seems to come from valuing different criteria and trying to do different things.

## Tasks to be completed by a pipeline

Amazon's Pipelines system is designed to publish libraries and deploy web services, and is extremely good at those tasks. That's all, though. If any post-build stages in your pipeline are doing anything other than "_take a built-image and update a running version of a software system to use that image, then run any associated tests and block the pipeline if appropriate_", You Are Going To Have A Bad Time. For instance, if you want a stage to run arbitrary bash code, or to make an HTTP request, or upload a generated artifact to S3, or whatever, you _can_ do those things (usually by hacking them in as functionality executed by a "Test" after a stage, or by setting up an external listener for SNS notifications), but you'll be fighting friction along the way. Developers who wish to do those things may, therefore, conclude that Pipelines is a bad tool; but they'd be wrong to do so. Pipelines is a excellent tool _for what it aims to do_, which is purely and simply "_publish a new version of a library_" and/or "_update the running versions of a web service_". It may be a bad tool _for your use-case_, but that doesn't make it a bad tool[^seven-languages].

The first obvious question then becomes - how often do developers want to do something outside of those two tasks? And I _think_ the answer is...almost never? I guess deployment of mobile apps would be one example (publishing an `.apk` probably looks different than building and publishing a Java/Python/etc. library, especially since you would need to run tests on deployed hardward before finalizing the publication), but I'm not really aware of any other examples. Please let me know if I'm missing something!

It is important to acknowledge, though, that Pipelines is _only_ a good solution in a corporate culture where there is one-and-only-one tool for the various SDLC functions (build, image storage, deployment, testing, etc.). With that level of standardization, your CD system can essentially accept configuration rather than code - tell it the names of your packages, the number of stages you want, etc., and it can spin up a personalized instance of The One Solution from your configuration parameters and a template. In the OSS world where the freedom to plug in different providers (GitHub/Gitea/GitLab, CircleCI/Drone/Woodpecker/Jenkins, Argo/Flux, etc.) is important, that "templatization" is nigh-impossible, and your pipeline definition has to be logic, not just parameters. That is - while I do miss Pipelines, I recognize it couldn't fly in the outside world.

## Different conceptualizations of a pipeline in OSS vs. Amazon

Unsurprisingly, I came out of Amazon with an Amazonian view of the relationship between a pipeline and a service - that is:
1. They're one-to-one - if you own and operate FooService, there is a single FooServicePipeline which manages build and deployment for the service (with pipeline stages corresponding to the various deployments of the service), rather than separate pipelines for build and for each deployment.
2. Multiple "waves" or executions can be progressing through a pipeline at a given time. The pipeline should take responsbility for ensuring that promotion into a stage does not start until the previous promotion has completed.
3. The version which is deployed to each stage is an emergent property of the executed logic of the pipeline, rather than being an input _to_ the pipeline.

After nearly two years of experience with OSS offerings, my views are a bit more nuanced and broad.

### One Pipeline per Service

I still tend to think that this is the most intuitive design - though, in fairness, you can squint and make "_one pipeline with multiple stages_" and "_one pipeline which orchestrates multiple sub-pipelines (which are each responsible for a stage of the overall-pipeline)_" look the same. This is really a question of definition - if you define "_pipeline_" as "_the thing which handles build and deployment for all stages of the service_", then by-definition there's only a single one. If you define "_pipeline_" as "_a sequence of steps to be executed_", then it's reasonable to say "_there's a pipeline for deploying to QA stage, there's a pipeline for deploying to Prod stage, and there's a pipeline for triggering those one-by-one_".

The important part, though, is the ability to set up dependencies and relations _between_ the stages - "_whatever was just deployed to QA stage (and passed tests) should now be promoted to Prod stage_". Thus, if you take the "_one pipeline per stage_" approach, there _must_ be an "over-pipeline" to make a change from one to the other; even if it doesn't exist as a standalone entity, and only exists implicitly in conditional logic determining whether completion of one step will trigger another. Which brings us to...

### Promotion Isolation

**Problem:** One thing (of many!) that Amazon Pipelines did _really well_ was to keep promotions isolated from one another. If a promotion is underway to Stage N and a promotion just succeeded to Stage N-1, the incoming promotion won't trigger until the ongoing one has completed. This is naturally desirable - each promotion should acquire a "lock" on a stage that is not released until the change being promoted has been tested.

**Solution:** This is possible to replicate in some OSS systems by limiting max-concurrency of executions to 1. If using the single overall pipeline model, this is a somewhat-extreme option which reduces throughput - if two changes are submitted in quick succession, the second change cannot begin flowing through the pipeline until the first one has completed (or failed along the way), so of _course_ there can be no race condition for a single stage - so, OSS systems probably work better with a model where each stage's deployment, and each stage-to-stage promotion, is a standalone pipeline.

**Problem:** Depending on team preference, it was also common at Amazon to configure the pipeline so that promotion into any non-prod stage will require manual approval if the previous promotion failed. This is so that a failed deployment can be preserved for debugging, rather than being overwitten by the next change that comes down the pipeline, which will obfuscate the original error.

**Solution:** I still haven't found a good way to implement this with OSS systems - this level of intra-step awareness seems to not be a common requirement of the systems. A deployment step(/pipeline) seems to only "_know about_" its own context, not the history of the "_next_" stage - indeed, the very notion of sequential stages does not seem to be "_baked in_" to these systems (see the earlier point that OSS pipeline systems are intentionally more abstract to support more supporting services, at the cost of having fewer high-level concepts available). One could of course implement this awareness, by extending the deployment step with API calls to the pipeline system which identify the next step and retrieve its history - but that's home-rolled implementation of functionality that I'm used to having provided "for free".

### The pipeline is a software system which decides what should be deployed where, rather than a system which is told what to deploy

This is the big conceptual change that took me a long time to adjust to in OSS systems. In my opinion, the input parameter to a(n overall) deployment pipeline should be "_the set of software packages to watch, build, and deploy_", **not** "_which built-versions should be deployed where_". The pipeline _itself_ is the software system responsible for triggering a deployment, running tests against the deployment, and determining whether the tests passed - and so, you should be _asking_ the pipeline "_is it correct to deploy image `deadbeef` to stage N+1?_", not _telling_ it to do so. Directly "injecting" stage/version mappings into the pipeline (by writing to the Deployment Repo) breaks sequentiality - it becomes possible to deploy something to stage N+1 other than the version which was just deployed to stage N, thus obviating all the benefits of sequential deployment and testing[^emergency-deployments].

Having stewed on this a little, and with the benefits of writing this post to disambiguate the differing views of pipelines, I think I've reached a good solution, though:
* Structure the deployment logic (in whatever automation system runs your pipeline) as taking a version and a stage as parameters.
* Write deployment logic which updates the Deployment Repo with the appropriate version, _and lock down permissions on the Deployment Repo so that only these automations can change it_ (though, see the last paragraph of this section)
* Either through an over-pipeline, or by adding a direct API call to the automation system at the end of a successful deployment, have the successful completion of "_deploy version X to stage N_" trigger a deployment of version X to stage N+1 (optionally, _if_ stage N+1's previous deployment was successful).

That way, the Deployment Repo becomes "internalized into" the pipeline - instead of the Repo being the interaction point at which the developers _tell_ the pipeline what to deploy, it instead becomes a state-maintainance persistence store where the pipeline _keeps track of_ what is currently deployed where (and to which external systems like Argo can couple/listen, to do their logic).

There's still an issue here, because developers _need_ to have write-access to the Deployment Repo of a service in order to be able to manage infrastructure of the service. Since this repo is where the mapping of "_which images should be deployed to which stage_" is found, developers _have_ the ability to override the pipeline. That's a solvable problem, though - automated checks during PRs can ensure that only those with appropriate permissions make changes in this mapping, while allowing any developer to manage general infrastructure. Again - something to roll for oneself, rather than having the functionality provided by the system, but that's the trade-off you make for general-purpose functionality.


[^can-access-directly]: Note that Drone actually has [the capability to access Vault secrets directly](https://docs.drone.io/secret/external/vault/) without importing them into Kubernetes, but I'd rather stick with the established access method that I already know about unless there are use-cases for which it doesn't work. In particular, note that the Kubernetes Secrets Extension has an [available Helm chart](https://github.com/drone/charts/tree/master/charts/drone-kubernetes-secrets) but the Vault Secrets Extension [doesn't](https://github.com/drone/charts/tree/master/charts)
[^sketchy-documentation]: Though do note the slightly misleading documentation - the docs instruct you to "_\[d\]eploy the secret extension in the same Pod as your Kubernetes runner._", but it seems that this is unnecessary and the extension can be deployed as a standalone pod (indeed, there's a [whole standalone Helm chart for it](https://github.com/drone/charts/tree/master/charts/drone-kubernetes-secrets)). In addition, the first paragraph in the [Kubernetes Secret](https://docs.drone.io/secret/external/kubernetes/) and [Kubernetes Secret Extension](https://docs.drone.io/runner/extensions/kube/) seem to be copy-pasted, and it's confusing that the [`extensions/secrets`](https://docs.drone.io/extensions/secret/) docs page links directly to the code of the Kubernetes Secret Extension rather than to its [docs page](https://docs.drone.io/runner/extensions/kube/). I've had a really tough time with Drone's documentation - in particular, there are plenty of contradictory indications of whether the Kubernetes runner is [deprecated](https://github.com/drone/charts/tree/master/charts/drone-runner-kube) or [not](https://docs.drone.io/pipeline/kubernetes/overview/). Functionality is also middling - I still can't believe that building with `buildx` requires [a plugin](https://github.com/thegeeklab/drone-docker-buildx)! If someone were starting afresh with CI, I'd definitely advise them to check another solution - current top of my list to checkout is [Woodpecker](https://woodpecker-ci.org), or [CircleCI](https://circleci.com/) seems to be the industry standard.
[^auto-update]: As I'd done with the [auto-repo-update-drone-plugin](https://gitea.scubbo.org/scubbo/auto-repo-update-drone-plugin) code, which automatically updates an Deployment Repo with the appropriate image - though I've since learned that this is better done through [`kustomize edit set image`](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/image.md).
[^seven-languages]: Shout-out to the excellent [Seven Langauges In Seven Weeks](https://www.amazon.com/Seven-Languages-Weeks-Programming-Programmers/dp/193435659X) book for introducing me to the notion that good design can include making it intentionally hard to do things with a particular tool, if that makes it easier/safer/faster to do the things you _want_ that tool to focus on. The Rust community take this idea to the extreme!
[^emergency-deployments]: Yes, breaking sequentiality is important functionality to make a direct (pipeline-circumventing) deployment in an emergency when you have an incident that can't be rolled back (say, due to non-backwards-compatible persistence changes) - but those should be extremely rare occurrences, not something to build your system around. Escalation to a dangerous-but-powerful privilege level should be extraordinary, not ordinary.

<!--
Reminders of patterns you often forget:

Images:
![Alt-text](url "Caption")

Internal links:
[Link-text](\{\{< ref "/posts/name-of-post" >}})
(remove the slashes - this is so that the commented-out content will not prevent a built while editing)
-->