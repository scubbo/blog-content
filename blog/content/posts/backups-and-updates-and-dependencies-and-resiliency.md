---
title: "Backups and Updates and Dependencies and Resiliency"
date: 2024-02-18T16:00:00-08:00
tags:
  - homelab
  - k8s
  - SDLC

---
This post is going to be a bit of a meander. It starts with the description of a bug (and appropriate fix, in the hopes of [helping a fellow unfortunate](https://xkcd.com/979/)), continues on through a re-consideration of software engineering practice, and ends with a bit of pretentious terminological philosophy. Strap in, let's go!
<!--more-->
# The bug

I had a powercut at home recently, which wreaked a bit of havoc on my homelab - good reminder that I need to buy a UPS! Among other fun issues added to my Disaster Recovery backlog, I noticed that the [Sonarr](https://sonarr.tv/) container in my [Ombi](https://ombi.io/) pod was failing to start up, with logs that looked a little like[^not-actual-logs]:

```
[Fatal] ConsoleApp: EPIC FAIL! 

[v4.0.0.615] NzbDrone.Common.Exceptions.SonarrStartupException: Sonarr failed to start: Error creating main database --->
  System.Exception: constraint failed NOT NULL constraint failed: Commandstemp.QueuedAt While Processing: "INSERT INTO "Commands_temp" ("Id", "Name", "Body", "Priority", "Status", "QueuedAt", "StartedAt", "EndedAt", "Duration", "Exception", "Trigger", "Result") SELECT "Id", "Name", "Body", "Priority", "Status", "QueuedAt", "StartedAt", "EndedAt", "Duration", "Exception", "Trigger", "Result" FROM "Commands"" --->
  code = Constraint (19), message = System.Data.SQLite.SQLiteException (0x800027AF): constraint failed NOT NULL
...
```

I could parse enough of this to know that something was wrong with the database, but not how to fix it.

After trying the standard approach of "_overwriting the database with a backup_[^backup]" - no dice - I went a-googling. It [seems](https://old.reddit.com/r/sonarr/comments/15p160j/v4_consoleapp_epic_fail_error/) that a buggy migration was introduced in `v4.0.0.614` of Sonarr, rendering startup impossible if there are any `Tasks` on the backlog in the database. Since my configuration [previously declared the image tag as simply `latest`](https://gitea.scubbo.org/scubbo/helm-charts/src/commit/3dfc818f5f58e3a733fd7acd22269bf1ac94d21a/charts/ombi/templates/deployment.yaml#L57)[^watchtower], the pod restart triggered by the power outage pulled in the latest version, which included that buggy migration. Once I knew that, it was the work of several-but-not-too-many-moments to:

* `k scale deploy/ombi --replicas` to bring down the existing deployment (since I didn't want Sonarr itself messing with the database while I was editing it)
* Spin up a basic ops pod with the PVC attached - frustratingly there's [still no option to do so directly from `k run`](https://github.com/kubernetes/kubernetes/issues/30645), so I had to hand-craft a small Kubernetes manifest and `apply` it.
* Install `sqlite3` and blow away the `Tasks` table.
* Teardown my ops pod, rescale the Ombi pod, and confirm everything working as expected.

# The first realization - automatic dependency updates

This experience prompted me to re-evaluate how I think about updating dependencies[^what-are-dependencies]. Having only had professional Software Engineering experience at Amazon, a lot of my perspectives are naturally biased towards the Amazonian ways of doing things, and it's been an eye-opening experience to get more experience, contrast Amazon's processes with others', and see which I prefer[^ci-cd].

I'd always been a bit surprised to hear the advice to pin the _exact_ versions of your dependencies, and to only ever update them deliberately, not automatically. This, to me, seemed wasteful - if you trust your dependencies to [follow SemVer](https://semver.org/), you can safely naïvely pull in any non-major update, and know that you are:
* depending on the latest-and-greatest version of your dependency (complete with any efficiency gains, security patches, added functionality, etc.)
* never going to pull in anything that will break your system (because that, by definition, would be a Major SemVer change)

The key part of the preceding paragraph is "_if you trust your dependencies_". At Amazon, I did - any library I depended on was either explicitly written by a named team (whose office hours I could attend, whose Slack I could post in, whose Oncall I could pester), or was an external library deliberately ingested and maintained by the Third-Party Software Team. In both cases, I knew the folks responsible for ensuring the quality of the software available to me, and I knew that _they_ knew that they were accountable for it. I knew them to be held to (roughly!) the same standards that I was. Moreover, the sheer scale of the company meant that any issue in a library would be likely to be found, reported, investigated, and mitigated _even before my system did a regular daily scan for updates_. That is - the possible downside to me of automatically pulling in non-major changes was practically zero, so the benefit-ratio is nearly infinite. I can count on one hand the number of times that automatically pulling in updates caused any problems for me or my teams, and only one of those wasn't resolved by immediately taking an explicit dependency on the appropriate patch-version. Consequently, my services were set up to depend only on a specific Major Version of a library, and to automatically build against the most-recent Minor Version thereof.

But that's not the daily experience of developers, most of whom are taking dependencies mostly on external libraries, without the benefits of a 3P team vetting them for correctness, nor of accountability of the developing team to fix any reported issues immediately. In these situations - where there is non-negligible risk that a breaking change might be incorrectly published with a minor version update, or indeed that bugs might remain unreported or unfixed for long periods of time - it is prudent to pin an explicit version of each of your dependencies, and to only make any changes when there is a functionality, security, or other reason to update.

# The second realization - resiliency as inefficiency

Two phenomena described here -

* Having to buy a UPS, because PG&E can't be trusted to deliver reliable energy.
* Having to pin your dependency versions to not-the-latest-and-greatest minor-version, because their developers can't be trusted to deliver bug-free and correctly-SemVer'd updates.

...are examples of a broader phenomenon I've been noticing and seeking to name for some time - "_having to take proactive remediative/protective action because another party can't be trusted to measure up to reasonable expectations_". This is something that bugs me every time I notice it[^examples], because it is inefficient, _especially_ if the service-provider is providing a(n unreliable) service to many customers. At what point does the cost of thousands of UPSes outweigh the cost of, y'know, just providing reliable electricity[^complexity]?

In a showerthought this morning, I realized - _this is just [resiliency engineering](https://sre.google/sre-book/introduction/) in real life_. In fact, I remembered reading a quote from, I think, the much-fêted book "[How Infrastructure Works](https://www.amazon.com/How-Infrastructure-Works-Inside-Systems/dp/0593086597)", to the effect that any resiliency measure "_looks like_" inefficiency when judged solely on how well the system carries out its function _in the happy case_ - because the objective of resiliency is not to improve the behaviour of the happy case, but to make it more common by steering away from failure cases. Hopefully this change of perspective will allow me to meet these incidents with a little more equanimity in the future.

...and if you have any recommendations for a good UPS (ideally, but not necessarily, rack-mountable), please let me know!

[^not-actual-logs]: I didn't think to grab actual logs at the time - it was only in the shower a day or two later that I realized this provided the jumping-off point for this blog post. These logs are taken from [this Reddit post](https://old.reddit.com/r/sonarr/comments/15p160j/v4_consoleapp_epic_fail_error/), which I found invaluable in fixing the issue.
[^backup]: Handily, Sonarr seems to automatically create a `sonarr.db.BACKUP` file - at least, it was present and I didn't remember making it! 😝 but, even if that hadn't been the case, I [took my own advice]({{< ref "posts/check-your-backups" >}}) and set up backups with [BackBlaze](https://www.backblaze.com/), which _should_ have provided another avenues. That reminds me...the backup mechanism is overdue for a test...
[^watchtower]: I know, I know...installing [Watchtower](https://containrrr.dev/watchtower/) is on my list, I swear!
[^what-are-dependencies]: in this section I'm using "dependencies" to refer to "_software libraries used by the services that I as a professional software engineer own-and-operate_", but most of the same thinking applies to "_image tags of services that I deploy alongside my application that are owned and developed by people other than me or my team_".
[^ci-cd]: I will die on the hill that Amazon's internal [CI/CD system](https://blog.scubbo.org/posts/ci-cd-cd-oh-my/) is dramatically superior to any Open Source offering I've found, in ways that don't seem _that_ hard to replicate (primarily, though not solely, image specifications based on build metadata rather than hard-coded infra repo updates), and I'm frankly baffled as to why no-one's implementing their functionality?[^cunningham]
[^cunningham]: Yes, this _is_ a deliberate invocation of [Cunningham's Law](https://en.wikipedia.org/wiki/Ward_Cunningham#Law). _Please do_ prove me wrong!
[^examples]: Though, having _finally_ gotten around to blogging about it, I now can't bring to mind any of the examples that I'd noted.
[^complexity]: I'm glossing over a lot of complexity, here, and deliberately hand-waving away the fact that "_every problem looks easy from the outside_". It's perfectly possible that the difficulty of going from [5 9's](https://en.wikipedia.org/wiki/High_availability) of electrical uptime to 100% is impractical - that "_[the optimal amount of powercuts is non-zero](https://www.bitsaboutmoney.com/archive/optimal-amount-of-fraud/)_" - or that occasional powercuts aren't as impactful to the average consumer as they are homelab aficionadoes. Frankly, I doubt both points, given what I've heard about PG&E's business practices - but, nonetheless, the fact remains that every marginal improvement to a service-provider's service has a leveraged impact across all of its consumers. That break-even point might fall at different places, depending on the diminishing returns of improvement and on the number of customers - but the magnifying effect remains.
