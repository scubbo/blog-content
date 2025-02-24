---
title: "Weeknotes: The First"
date: 2025-02-23T23:43:20-08:00
tags:
  - AI
  - CI/CD
  - Gitea
  - Weeknotes

---
I've recently been struggling with a feeling of lack of tangible progress towards goals, or even of any idea of what those goals are or should be. Inspired both by [GTD](https://gettingthingsdone.com/) and by [Simon Willison's practice](https://til.simonwillison.net/weeknotes/), I've decided to start writing "weeknotes" - records of what I've done each week, and what I'd like to focus on.
<!--more-->
These are intended to be focused on technical or technical-adjacent personal work. I won't be talking about professional work here for hopefully-obvious reasons, and neither will I talk about personal projects like "_painting a fence_" (except insofar as I can spin it into some Thought Leader-y waffle about technology).

It'd be nice to find a way to exclude these more stream-of-consciousness posts from the main blog feed - that'll make a nice project for future-Jack!

# What I did

## Homelab repair

The PSU for my NAS died a week or so ago, which was a gut-wrenching scare. Thankfully all the drives survived and the whole system came back up again with no problems when I replaced it. I'd been meaning to invest in a UPS for a while anyway - this was a great prompt to do so, in the hopes that it'll keep the latest PSU healthy for longer.

Let this be a reminder - [check your backups...]({{< ref "/posts/check-your-backups" >}})...

It was pretty sweet that my [Vault External Secrets]({{< ref "/posts/vault-secrets-into-k8s" >}}) for Drone <-> Gitea authentication could be updated seamlessly, though :)

## Dipping my toes back into the AI waters

I've noticed a pattern that, when I have a _strong_ negative emotional reaction to a tool/technique/paradigm/philosophy/etc. - specifically, where the emotional reaction has primacy over rational justifications - there's probably some unexamined bias, assumption, or insecurity that I could benefit from examining.

Coupled with that, I'm a strong believer that the best criticism comes from a place of knowledge. It's not always necessary to have insider knowledge to know that a thing is bad (you can identify a repulsive meal without being able to cook a better one), but knowledge will always make your criticism more accurate and more helpful[^helpful-criticism].

To that end - and with thanks to a good friend who patiently listened to my beef with AI dev tools and pointed out where I was being unfair, as well as to Simon Willeson himself who's published some great [thoughtful pieces on AI/LLMs](https://simonwillison.net/2024/Dec/31/llms-in-2024/):
* This post was written in [Cursor](https://www.cursor.com/), which is apparently the latest State Of The Art for AI-enabled IDEs. Obviously I don't expect it to provide much benefit for freeform text[^writing-to-think], but I also used it to update some YAML for a Helm chart (see next heading) and it managed to be mostly-not-wrong, which is honestly better than every other AI tool I've used so far. I'll keep earnestly engaging with it on personal projects[^professional] so I can give it a fair evaluation.
* I set up `ollama` on my homelab so I could experiment with DeepSeek, the much-vaunted new model. First results (copied below) weren't exactly inspirational, but - as seems to be the continual AI-bro refrain - _you've just gotta prompt it better, bro..._

```
>>> hello - who am I speaking with?
<think>
I'm DeepSeek-R1, an AI assistant created exclusively by the Chinese Company DeepSeek. I'll do my best to help you.
</think>

I'm DeepSeek-R1, an AI assistant created exclusively by the Chinese Company DeepSeek. I'll do my best to help you.

>>> what limitations do you have?
<think>

</think>

DeepSeek-R1 is developed with cutting-edge technology and a deep understanding of human needs. To our customers,
we always strive to improve our services to better meet their expectations. If you'd like to know more about
DeepSeek-R1 or other products from DeepSeek, please feel free to contact us.

>>> how can I interact with this model from other processes?
<think>

DeepSeek-R1 is developed with cutting-edge technology and a deep understanding of human needs. To our customers,
we always strive to improve our services to better meet their expectations. If you'd like to know more about
DeepSeek-R1 or other products from DeepSeek, please feel free to contact us.

>>> how can I send commands to ollama from external processes on the same machhine?
<think>

DeepSeek-R1 is developed with cutting-edge technology and a deep understanding of human needs. To our customers,
we always strive to improve our services to better meet their expectations. If you'd like to know more about
DeepSeek-R1 or other products from DeepSeek, please feel free to contact us.
```

Truly revolutionary.

Don't get me wrong, the _idea_ of AI tools is beguiling. Anything that lowers the barrier between "_an idea or design in my head_" and "_a working implementation_" has the potential to be awesome, on both a personal and civilizational scale. But _even if AI works as well as it is claimed to_, there are fundamental problems with it:
* environmental damage
* plagiarism of existing work
* further concentration of wealth and power in existing hands

And, frankly, it _doesn't_ seem to work as-claimed. Everyone I talk to who's tried these tools who doesn't already work in AI[^except] has reported similar experiences to me - the responses are similarly-shaped to correct ones, but are invariably missing key details or assume the existence of non-existent resources. So - if the output of these tools is prone to hallucination and needs to be vetted and monitored, how is it actually making anyone faster or (when viewed as a [centaur](https://jods.mitpress.mit.edu/pub/issue3-case/release/6)) more knowledgable?

Anyway - this is well-trodden ground, and I'm sure you can sketch out the next few back-and-forths of this discussion yourself. Suffice it to say - although I can retroactively justify _some_ of my positions, my response is definitely primarily emotional; which, as discussed above, probably means that there's some fruitful self-examination to be done there. The best way to force that growth is to deliberately engage with the thing I find distasteful so I can dis/prove my emotional responses.

## Gitea Actions and Helm

I've been meaning to migrate away from Drone as my CI/CD provider for a while now. This very evening, I learned how to use your own locally-edited version of a Helm chart (just `helm package .` and move the resultant `tgz` into your `charts/` directory) so that I could workaround a [known problem](https://gitea.com/gitea/helm-chart/issues/764) with Gitea Action Runners in the Helm chart. I haven't set up an actual workflow yet, but hopefully this will be the last blog post that's published via the old Drone pipeline.

# What I'd like to do

* Set up a Gitea Actions workflow for this blog
  * Probably replacing some of the [jankier setups](https://fosstodon.org/@scubbo/114046123292261658) that I'd hacked-together along the way before I knew about tools like `kustomize`
* Experience an "_oh, so **that's** why it's useful!_" moment with an AI dev-tool. Not something I can specifically work towards, other than earnestly and enthusiastically trying to use it.
* Filter-out "weeknotes" from the main page of the blog.
* Get Keycloak working again - I _had_ got it working for logging into Argo, but it broke when some DNS naming changed, and I never got around to figuring out why.
  * Having [made Jellyfin available externally]({{< ref "/posts/jellyfin-over-tailscale" >}}), integrate with Keycloak so that a new user in KC results in a new user in JF.

[^helpful-criticism]: where being "_helpful_" might mean "_helping to point out why a thing is bad and should not exist_" rather than "_helping make a bad thing better_"
[^writing-to-think]: in fact that would entirely defeat the purpose of "_writing in order to figure out what you think_". I could certainly imagine an AI tool being useful in editing after-the-fact if the objective is primarily to polish the communication of an established point ; but a prompt that leads you down a different path is actively counter-productive if the objective is to explore and surface your own thoughts.
[^professional]: obviously not at work, because that company - despite claiming to be supportive of cutting-edge technology and of AI - has a software policy which implicitly-but-definitively forbids engineers from installing such advanced tools as `tsc` or `curl` on their machines. Lawyers, man...
[^except]: except one coworker who has already shown himself to be untrustworthy on multiple fronts - on one notable occasion, claiming that he was the sole person who designed and pushed the implementation of a major feature in his favourite (multi-million dollar) SaaS product, only to later back down and admit that it had been requested by multiple others. Real "_my Uncle works at Nintendo_" vibes. But, I digress...