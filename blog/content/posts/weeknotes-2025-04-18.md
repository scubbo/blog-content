---
title: "Weeknotes: 2025-04-18"
date: 2025-04-18T22:12:55-07:00
tags:
  - EDH-ELO
  - Homelab
  - K8s
  - Real-Life
  - Vault
  - Vercel
  - Weeknotes

---
Continuing my pattern of writing "week"notes every fortnight. It's not intentional, I swear, it's just working out that way!
<!--more-->

# What I Did

* The [Gitea PR for OIDC](https://github.com/go-gitea/gitea/pull/33945) is still open, though it's had a milestone label attached, so I'm hopeful that it'll get merged soon.
* I finally got a working replacement PSU for my NAS (the original broke back in early February, and I received two replacements that had the incorrect cables in that time), so was able to get my NAS _properly_ installed back in the rack - until now, it'd been awkwardly half-hanging-out, with a differently-sized PSU _outside_ the case with cables snaking Frankensteinily in. Nice to get that tidied away! Although...
* ...power-cycling my NAS (and, therefore, my clusters, both hardware and software) highlighted some cold-start problems of Pods mounting persistence. Thanks to [this issue](https://github.com/kubernetes/kubernetes/pull/119735) I found that updating to a newer version of `k3s` did the trick - but that _itself_ came with a host of teething troubles. Still - they got ironed out, and the cluster is now more resilient and fully-featured for it, and [all it cost me](https://xkcd.com/349/) was a couple hours' sleep :P
  * I also reinstalled a Raspberry Pi board that had been nonfunctional with a broken SD card for months. Back up to 4 nodes in the cluster!
* I implemented a feature in [EDH ELO](https://gitea.scubbo.org/scubbo/edh-elo) that I'd been meaning to do for some time - the [ability to seed the database](https://gitea.scubbo.org/scubbo/edh-elo/commit/9b4e6c3b4d852883a372332461253ef9eae6d014) by directly reading the source-of-truth[^persistence] Google Sheet, rather than me down/uploading `.csv`s every time I wanted to update. Cursor/Claude was a major help - as usual, it couldn't get 100% of the way there by itself, but it got me pretty damn close way faster than I would have with documentation alone.
  * Along the way, I [tried](https://gitea.scubbo.org/scubbo/helm-charts/commit/6aba9bf11b15b28e790cdeced9dbe73a0062a8f6) using [Vault Sidecar Injection](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar#configure-kubernetes-authentication)[^vso]. I'd always found it pretty tricky[^dudo] to compare these and the other methods of Vault injection ([BanzaiCloud's webhook](https://bank-vaults.dev/docs/mutating-webhook/), the [External Secrets Operator](https://external-secrets.io/latest/), probably several others I'm unaware of) - without using them, it's hard to get a handle on their ergonomics. And this is why we homelab!
  * Perhaps a comparison of these methods would be a blog post in the future! TL;DR of what I found - the VSO writes the data _as_ a Kubernetes Secret, which can be referenced as an Env Variable, whereas VSI writes the data into the Pod's filesystem. Ergonomics aside, VSI should be preferred as Kubernetes Secrets [are not actually entirely secure](https://kubernetes.io/docs/concepts/configuration/secret/).

# What I'll Do

## Move to Vercel

Now that it's been announced at work, I guess I can also write here that - I'll be leaving my current job this coming Thursday 24th, and starting at Vercel on the 28th. I'll be working on their internal DevX Platform, so much of the responsibilities will be the same - tooling, automation, process improvement - but I'm really hopeful that the culture of "_a technology company_" (rather than "_a company that uses technology_") will be more-aligned with how I prefer to work.

I'm especially excited to work at Vercel in particular, as their product focus will help me to strengthen in two areas where I could benefit from improvement:
* [`next.js`](https://nextjs.org/) is a Frontend framework; I can sling some HTML/CSS/JS, but I'm definitely more of a Backend-and-Ops guy, so rounding out that skillset will be a good exercise.
* [Turborepo](https://turbo.build/) is a build system intended for monorepos. I have long felt considerable cognitive dissonance at the twin facts that:
  * Most of the [claimed benefits of Monorepos](https://monorepo.tools/) feel, to me, either like simply "_benefits of good tooling_" (i.e. neither monorepos nor polyrepos are "better", here - good tools are just better than bad tools), or as active _drawbacks_ (I'll save that for another, spicier, post :P ).
  * And yet, lots of smart people seem to genuinely and enthusiastically find them helpful.

So, I _must_ be missing some advantage of monorepos - but, unfortunately, it's not the kind of system that you can trivially spin-up on a homelab to experience, you really need to work in a "real" one in order to get a feel for it. I'm hoping that a position at Vercel can give me the opportunity to learn what I'm missing!

## Continue AI Experimentation

Having recently been converted to "_AI Development Tools are Useful, Actually_", I'm also interested to see how [v0](https://v0.dev/) stacks up against Claude. I've also been tinkering with self-hosting some AI models[^gpu], and it's really highlighted how patchy my understanding is of the layers of the stack. I'd love to dig a little deeper into understanding those system design concepts.

[^persistence]: The dream would be for this application _itself_ to be the Source Of Truth. But that requires availability and durability guarantees that are _far_ beyond what I'm willing to commit to at this point. My playgroup's match history is more emotionally important to me than the data of any company I work at! (hello prospective employers. For legal reasons, the preceding comment is a joke)
[^vso]: As opposed to the [Vault Secrets Operator](https://blog.scubbo.org/posts/vault-secrets-into-k8s/), which I'd previously written about [here]({{< ref "/posts/base-app-infrastructure" >}}) and [elsewhere]({{< ref "/tags/vault" >}})
[^dudo]: Not helped by a Principal Engineer colleague who straight-up stated that he likes to withold information from people because, quote, "_I had to work to get this information, I feel like others should too_". But I digress...
[^gpu]: My 4Gb GPU can _just about_ run some of the most stripped-down models, but I sense some more hardware investment in my future...
