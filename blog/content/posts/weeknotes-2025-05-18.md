---
title: "Weeknotes: 2025-05-18"
date: 2025-05-18T16:02:14-07:00
tags:
  - AI
  - Homelab
  - Information-Management
  - Reading
  - Vercel
  - Weeknotes

---
Wow, have I really been at Vercel for three weeks? Time flies when you're learning fast!
<!--more-->
# What I Did

## At work

Ramping up at Vercel has taken the majority of my mental and emotional energy. It is _radically_ different from anywhere I've worked before - the culture is electric and energizing. For someone accustomed to red tape, foot-dragging, and pessimism, it's been actually unsettling to be surrounded by so much optimism and positivity - it reads to me as disingenuous. Which, to be clear, is a "me-problem", not a comment on that behaviour - I knew going into this role that it would afford me opportunities to [learn about new technical areas]({{< ref "/posts/weeknotes-2025-04-06#move-to-vercel" >}}), but it turns out to be giving me an opportunity for emotional growth as well!

On the technical side, though - a coworker was finally able to convincingly articulate to me why monorepos _are_ an attractive pattern, even in the presence of good service-creation tooling and extractable CI/CD workflows. The core point I'd been missing was - monorepos do not _force_ all components (services/packages) to depend on the same version of an (internal or external) package, they merely _encourage_ it. In situations like a zero-day drop[^fastest-upgrade-possible], or a hairy breaking-change for an internal package[^test-run-upgrade], you can deliberately break that lockstep for as long as you want, and then return to it once out of the critical migration portion. Now that I know that that's not a drawback, the other advantages actually look way more compelling. Thanks for the explanation, Brandon!

I must say, it's refreshing to work at an actual "_technology company_", as opposed to "_a company that works with technology_" (which, if you're charitable, could be a description of LegalZoom). On Friday I spent ~20 minutes hacking around with bash-scripting to implement some functionality in our [build tooling](https://turborepo.com/), before realizing that is already came built-in. Contrast this with LegalZoom, where a Principal Engineer declared _in 2024_ that "_we've moved our workloads to Kubernetes - **we're in the future**_"[^dudo-sucks]. Quite.

## Personal Projects

I finally caved and bought myself a top-notch GPU (Nvidia RTX 5090) so that I could self-host some AI-related tooling to get a better understanding for how it works. And as a side-effect, hopefully Factorio's Gleba will be able to render on something above minimal settings now! Sadly my motherboard is so old that the brand-spanking new case I bought (the old one literally wouldn't fit it in!) isn't operating at peak spec - the RGB fans on front and back aren't lit, and there's no mobo connector for USB-C port on the front - but it's still a lovely little toy.

![An RTX 5090 will not fit into a case from 2005](/img/rtx-5090-does-not-fit-1.jpg "An RTX 5090 will not fit into a case from 2005")

![Second View](/img/rtx-5090-does-not-fit-1.jpg "Second View")

![Less RGB than I would like, but still...purty...](/img/rtx-5090-in-new-case.jpg "Less RGB than I would like, but still...purty...")

Along the way I've learned how to set up WSL, which was surprisingly painless, aside from [making services available over the network](https://stackoverflow.com/questions/49835559/access-a-web-server-which-is-running-on-wsl-windows-subsystem-for-linux-from-t) - seems like the out-of-the-box solution is only available on Windows 11, which my CPU doesn't support, so I have had to use [this workaround](https://gist.github.com/daehahn/497fa04c0156b1a762c70ff3f9f7edae?WT.mc_id=-blog-scottha) script (via [Scott Hanselman](https://www.hanselman.com/blog/how-to-ssh-into-wsl2-on-windows-10-from-an-external-machine)). [Obsidian](https://obsidian.md/)'s been invaluable for note-taking!

I also took the opportunity to buy a(nother) PowerEdge R430 off a friend who was moving to New York, so my homelab is even more over-scaled. Soon it'll be time to buy a new switch...and then a new rack...

And finally, I started reading [Changing Minds](https://www.amazon.com/Changing-Minds-Computers-Learning-Literacy/dp/0262541327) after seeing a recommendation in a [Lobste.rs](https://lobste.rs) comment section. Quite the time capsule of seeing what people in 2001 thought computers could be!

# What I'll Do

* Continuing to ramp-up at Vercel will likely keep taking the majority of my time and energy - which, honestly, is as it should be. I'm wary of my tendency to over-commit to work, but - at least at-present - this seems to be a place that will reward investment-of-effort, and I'm excited to be stretched and challenged and learning again. I finally understand what my friend Jeff was talking about when he was talking about the pleasurable aspects of working somewhere whose values align with yours!
* That said, I'd love to make the time to start a toy project on next.js/Vercel, to get a better understanding of the products' strengths.

[^fastest-upgrade-possible]: Where you actively want all consumers of a package to upgrade to the fixed version, without waiting to update all at the same time.
[^test-run-upgrade]: Where you might want to work closely with a partner team to "test-run" the migration rather than updating all consumers at once
[^dudo-sucks]: In fairness, that particular guy was engaged in enthusiastically brown-nosing our Chief Architect at the time, so (as was so often the case with anything he said) you can't really be sure whether he meant it, or was just being manipulative. I'm not sure which would reflect worse on him.
