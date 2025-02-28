---
title: "Gitea Actions"
date: 2025-02-27T21:25:00-08:00
tags:
  - CI/CD
  - Gitea
  - Homelab
  - K8s
  - Meta

---
As I hoped in my [last post]({{< ref "/posts/weeknotes-the-first" >}}), I've set up [Gitea Actions](https://docs.gitea.com/usage/actions/overview) on my homelab, with a view to completely replacing [Drone](https://docs.gitea.com/usage/actions/overview) which I've found to be pretty buggy and missing some core features[^ill-featured]. The process was _reasonably_ smooth, but not entirely turnkey, so I've laid out the steps I took in the hopes that they'll help someone else.
<!--more-->
I'm using the [Helm Chart](https://gitea.com/gitea/helm-chart/) to manage my Gitea installation - if you want to install Action Runners separately, there's a good guide [here](https://docs.gitea.com/usage/actions/quickstart).

# Step-by-step instructions

## Upgrade

First and foremost - Gitea Actions was introduced in Gitea 1.19, but in practice I [found](https://gitea.com/gitea/helm-chart/issues/813) that some of the feature of the Helm Chart required at least `1.24.0`[^patch-version]. You'll also need your Helm Chart to be on at least `10.6.0` - read the [upgrading guide](https://gitea.com/gitea/helm-chart/#upgrading) _carefully_, I nearly borked my whole installation by jumping versions too quickly. [Here's](https://github.com/scubbo/pi-tools/commit/2b72a106ec14f042428058b94a0b38f7f0bcc8f1) my upgrade.

## (Potentially) Patch the Helm Chart for persistence

Depending on how you provide PVs to your Pods, this might not affect you, but I and some others found a [bug](https://gitea.com/gitea/helm-chart/issues/764) whereby the (hard-coded) PV size for the Runners was too small to be provided by the provisioner (honestly didn't even know that was a constraint that existed!). This gave me a great opportunity to learn how to use a locally-developed Helm Chart (rather than a published one) as a dependency for your own, and it was super-easy, barely an inconvenience:

* Clone the [chart](https://gitea.com/gitea/helm-chart)
* Make whatever alterations you want ([e.g.](https://gitea.com/gitea/helm-chart/pulls/812))
* If the chart has dependencies (as Gitea's does), run `helm dependency update`
* Run `helm package .` from the root of the repo - this will create a file named `<name>-<version>.tgz`, where those variables are taken from the `Chart.yaml`
* Move that archive into `charts/` in your own chart's directory - so long as the version number matches the desired-version specified in your own `Chart.yaml`, it will be picked up over a remote version.

## Adapt your workflow to the absence of Node

At this point, you should be able to run a workflow (don't forget that you need to [enable repository actions](https://docs.gitea.com/usage/actions/quickstart#use-actions) on a repo-by-repo basis), but you might notice that `actions/checkout` fails with `'node' not found in $PATH`, even when following the [Quickstart example](https://docs.gitea.com/usage/actions/quickstart). Some lengthy investigation [here](https://gitea.com/gitea/act_runner/issues/538) highlights differences between Gitea Actions Runners and GitHub Actions Runners - TL;DR, you need to:
* Update `runner.labels` in the `gitea-act-runner-config` ConfigMap to include `"ubuntu-latest:docker://gitea/runner-images:ubuntu-latest"` (as [here](https://github.com/scubbo/pi-tools/blob/main/k8s-objects/helm-charts/gitea/values.yaml#L93))
* Install Node _before_ using the `actions/checkout` action, as [here](https://gitea.scubbo.org/scubbo/blogcontent/src/commit/5176ec26ff679ee9ebde6467eefed8d8c39d775c/.gitea/workflows/publish.yaml#L9-L14).

If you're going to use Gitea Actions a lot, it's probably sensible for you to create your own base image with Node preinstalled.

## Plumbthrough Docker Socket

If you're going to be using Actions to build a Docker image, you'll need to make the Docker socket available to the Docker-in-Docker containers that run _within_ the `act_runner`. [This comment](https://gitea.com/gitea/act_runner/issues/280#issuecomment-898726) by `@javiertury` was very helpful, especially once I realized that setting `DOCKER_HOST` on the runner-pod is not the same thing as setting it on the containers that run _within_ that pod - you can see the full configuration I needed [here](https://github.com/scubbo/pi-tools/blob/main/k8s-objects/helm-charts/gitea/values.yaml#L94-L109).

An alternative approach using the `kubernetes` driver is detailed [here](https://tobru.ch/gitea-actions-container-builds/). I haven't tried it - I do like the idea of jobs being standalone Pods, with all the control that k8s can offer (with annotations, operators, etc.), but I didn't fancy having to provide a `kubeconfig` and specify `driver: kubernetes` on every build step. I suppose it would be possible to abstract away that configuration by creating my own build-action - [the solution to every problem...](https://en.wikipedia.org/wiki/Fundamental_theorem_of_software_engineering)

Although, on second thoughts - if _only_ docker-builds run as separate pods, not _every_ job/step in a workflow, then that a) leads to some inconsistency, and b) limits the value of the k8s-magic that can be injected. Maybe it's less attractive than I thought.

## Inject secrets

In order to push to the Gitea Docker Registry, or to auto-update a Deployment Repo, the workflow needs to authenticate to Gitea with a PAT. By this point in the night I was getting pretty tired and impatient, so I took the simple route of [creating a secret in the repo](https://docs.gitea.com/usage/actions/secrets) containing the PAT; but it should be possible to use the [vault-action](https://github.com/hashicorp/vault-action) (remember, Gitea Actions is compatible with published actions for GitHub Actions!) to retrieve a secret, once Vault's been set up to accept OIDC auth. Actually _generating_ such a secret might be tricky - I know there's a [plugin to provide ephemeral finely-scoped GitHub Tokens from Vault](https://github.com/martinbaillie/vault-plugin-secrets-github), but I doubt it would be directly installable on Gitea.

I've still yet to plumb in the Telegram token I used to send myself a confirmation message after publication - good opportunity for the Vault-based approach.

## Update to more modern infrastructure management

This isn't something that _you_ need to do, but rather something that I had the _opportunity_ to do and that I want to brag about.

I'd previously been managing the infrastructure of this blog[^infrastructure] with a [Helm chart](https://gitea.scubbo.org/scubbo/blog-infrastructure), as that was the only way I could figure out to [extract some configuration from a definition so that it could be easily updated](https://gitea.scubbo.org/scubbo/blog-infrastructure/src/branch/main/helm/templates/_helpers.tpl). Since I've discovered `kustomize` in the intervening time, no reason not to [use it](https://gitea.scubbo.org/scubbo/blogcontent/src/commit/5176ec26ff679ee9ebde6467eefed8d8c39d775c/.gitea/workflows/publish.yaml#L93), in a repo that [conforms to normal naming conventions](https://gitea.scubbo.org/scubbo/blog-deployment). I also took this opportunity to move the Argo App Definition from a [repetitive declaration in a long YAML file](https://gitea.scubbo.org/scubbo/helm-charts/commit/fb7e8cd98e37db111bed0bd3c983e2e0157b4be6#diff-9274f28f68613fb77d22af9241e5f859b4c035b8) to a [concise invocation](https://gitea.scubbo.org/scubbo/helm-charts/commit/fb7e8cd98e37db111bed0bd3c983e2e0157b4be6#diff-9aa4e4421d8484121d4344945de5fe2b6e99bf37) of an [extracted template](https://gitea.scubbo.org/scubbo/helm-charts/commit/fb7e8cd98e37db111bed0bd3c983e2e0157b4be6#diff-1b8af0da046a40253682f731d114cef2e87ea244).

## Next Steps

(Again - this is for me, not you!)

* I might extract the "_build, push, and update the deployment repo_" logic to a standalone workflow. I've already done this at work, and it was very helpful there. I have fewer use-cases and parameters to support for my own use!
* As detailed above, reimplementing a Telegram notification when this publishes would be neat, as would the [post to Mastodon step](https://gitea.scubbo.org/scubbo/blogcontent/src/commit/e125f5795e95bddfc108641507b79b0d8add45f2/.drone.yml#L107-L132).
* And injecting secrets via Vault
* I don't have any plans to add a call to Argo to sync the app after updating the Deployment Repo - Auto-Sync has always been good enough for me.

A much larger-scale change (which might end up obsoleting Gitea Actions altogether) would be to install [CodeFresh](https://codefresh.io/) or a similar pipeline visualization and management tool; not that that's really relevant for the teensy single-stage "pipeline" of this blog, but I could deploy test apps with it to experiment. I've been out of Amazon for over two years, and I'm still aghast at how awful the accepted state-of-the-art is for Pipeline management in OSS tooling (as I previously blogged [here]({{< ref "/posts/ci-cd-cd, oh my" >}})). There doesn't seem to be any tool that takes the view that the Pipeline is a first-class entity which _manages_ the deployments and promotions, as opposed to deployments being the top-level concepts that are triggered by each other or by _<shudder>_ pushes to "_environment branches_". The "Deployments" page for GitHub is the closest thing I've found to a visualization, but it doesn't show you the actual state _of_ the pipeline, provide any controls to it (setting/overriding deployment windows, manually rolling-back/promoting/force-passing), or provide any built-in integrations like observability.

After searching the vendor floor at KubeCon last year, CodeFresh was the closest thing I could find to an actual Pipeline tool[^pipeline] - but, as with the other (even more awesome!) technology I discovered at that con ([Crossplane](https://www.crossplane.io/)), I haven't gotten a chance to actually use it at work yet.

# Why Gitea Actions?

A coworker asked this question (in comparison to "_why not self-hosted runners triggering from a GitHub repo?_"), and honestly it was a good question that helped me understand my own motivations better. The justifications I came up with were:

* There are many reasons to self-host, but primary for me is "_reducing dependence on, and power of, centralized providers_". I'm a big believer in the societal merits of many small actors collaborating via network effects, rather than many consumers using a central platform or service; although a single well-funded and -staffed provider can probably provide more features/content than the network example, it invariably comes at the cost of excessive monetization and enrichment of capital, walled gardens, privacy erosion, algorithmic behaviour influencing, and other undesirable outcomes. I don't hold any illusions that my tiny self-hosted forge is even the barest speck of a flicker on GitHub's radar - but leading by example, and living life authentically according to your values, are worthwhile in-and-of themselves even if they have no tangible external effects. And hey, who knows - if my example is enough to help just one other person start investigating ways to break out of the centralized tech monopoly that is [ruining our lives and civilizations](https://www.wheresyoured.at/never-forgive-them/), I'll consider that well worth it.
* A secondary reason I self-host is to learn how things work. This stands in contrast to _making_ things work - that's good as well, of course, but (so long as we're talking about non-essential services) I'd much rather have a semi-functional homelab with a hodge-podge of applications providing one-tenth of the functionality of a professional build, than to run a single command and have it all Just Work™️ _without understanding **how** it works_. This is a personal choice, of course - in business, the opposite choice is very often the correct one[^build-your-core-competency].
  * This realization also helped me understand my distaste for AI Dev Tools. _Prima facie_, a tool which simply solves the problem for you, without providing understanding to you, is distasteful; a tool that can give you an _incorrect_ understanding is abhorrent. As soon as I consciously recognized this reaction, however, I was quickly able to talk back to it[^mindfulness] - if one approaches AI-generated outputs with an appropriate amount of trust (which should _never_ be 100%), and an awareness for when one is within/outside the bounds of one's own competency, it can be an accelerant to learning as well as to simple execution.

You can of course "_learn things_" at different levels - I could just as well have viewed the "_self-hosted runners_" approach as "_I'm learning how to self-host runners that are triggered from GitHub_". But the former reason was convincing enough.

[^ill-featured]: It's telling that even the author of a [plugin that provides multiarch Docker builds on Drone](https://github.com/thegeeklab/drone-docker-buildx) has moved to another provider.
[^patch-version]: I'm guessing. I jumped straight from `1.20.0` to `1.23.4`, but from the source code it _looks like_ the feature was added in `1.23.0`.
[^infrastructure]: Such as it is - just a Deployment and a Service.
[^pipeline]: Honourable mentions to PipeCD, dishonourable mentions to Argo Kargo.
[^build-your-core-competency]: I can't find it right now, but I remember reading a great blog post asserting that the only thing you should really be building from scratch in a business is The Thing that your company is actually about - the distinguishing feature, the special sauce, the what-have-you that makes you different and (so you hope) better than your competitors. Everything else, buy it off-the-shelf as much as possible, so you can focus as much of your time and energy on the highly-leveraged thing that makes you special[^domain-driven-design]. In the absence of that blog post, I'll share the excellent, and much-aligned, [Choose Boring Technology](https://boringtechnology.club/) talk.
[^mindfulness]: This is your irregularly-scheduled reminder that the techniques of mindfulness have been around for millenia, and independently discovered and propagated at wildly disparate times and places with very little personal gain at stake. If you consider yourself a hardcore rationalist or scientific mind, the correct response to that is not "_that's all woo-woo bullshit, my mind is too ElEvAtEd for it_", it's "_hmm, there is overwhelming evidence to suggest that this is legitimate - I should look into this more_". Personally I like [Ten Percent Happier](https://www.meditatehappier.com/podcast), but work gives [Headspace](https://www.headspace.com/) for free so that's what I'm on right now.
[^domain-driven-design]: Now that I put it like that, it also sounds like the part I disliked most from the "Domain-Driven Design" book - the waffling about Core/Supporting/Generic subdomains - before it moved onto the actually useful and interesting concepts of Language Boundaries and making code objects reflect and represent mental models.
