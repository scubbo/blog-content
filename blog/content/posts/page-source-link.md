---
title: "Page Source Link"
date: 2022-05-30T21:22:04-07:00
tags:
  - meta
---
I just added a page-source link to my blog setup.
<!--more-->
You can see how it was done in the commit that introduced this blog post (just click the "Page Source" link that should be present in the header for this article![^1]):
* [Hugo](https://gohugo.io/) supports setting site-wide variables in [config files](https://gohugo.io/getting-started/configuration/), and suppors accessing information about the file that generated a give post with the [`File` object](https://gohugo.io/variables/files/). By setting a site-wide variable that points at [the base of my Git repo in my self-hosted Gitea instance](https://gitea.scubbo.org/scubbo/blogContent/src/branch/main), both of these pieces of information can be used at build-time to generate a page-specific URL to inject into the built page.
* I had to copy-in and overwrite the `layouts/_default/single.html` file from the theme I'm using ([Ananke](https://github.com/theNewDynamic/gohugo-theme-ananke)), because the aforementioned information is only available at build-time. If I'd have tried to inject this information by editing the page at view-time (with a Javascript file, as I've [done elsewhere](https://gitea.scubbo.org/scubbo/blogContent/src/branch/main/blog/static/js/custom.js) with simpler styling changes), the information wouldn't have been available.
  * OK, _technically_ I could probably have inserted both of those information pieces into the page in hidden elements, and then used Javascript to retrieve them and construct the URL, but why not do it directly at build-time?
  * The lines you're interested in are lines 50-52 of the file (at the time of first-commit - man, it's awkward that I can't add a link to a commit that hasn't been created yet, huh[^2]!?) - everything else is just a copy-paste of the existing layout from Ananke.
* The [`{{with}}`](https://gohugo.io/functions/with) function is a pretty neat way to do "_check if X exists, and use it in-scope if so; else, skip the scope below_".
* Note that I am not linking directly to the root of the _repo_ in `page_source_base` ([https://gitea.scubbo.org/scubbo/blogContent/src/branch/main/blog/](https://gitea.scubbo.org/scubbo/blogContent/src/branch/main/blog/)), but to a subfolder (`blog/`) within it. This is because I have my Hugo source in a subfolder within the repo, so that other configuration files (`Dockerfile`, CI/CD configuration, `.gitignore`, etc.) can live in the root and the source can be kept clean and separate.

Keen readers will notice I haven't discussed the [Gitea](https://gitea.io/en-us/) instance before. I've significantly revamped my setup recently, with Git hosting, CI/CD pipeline with [Drone](https://www.drone.io/), and deployment to a Kubernetes cluster, all self-hosted. I've been putting off a sequel to [the "self-hosting blog" post]({{< ref "/posts/self-hosting-blog" >}}) describing the process, but it's probably past-due by now!

[^1]: Or, now that the commit's actually been created and so is addressable, I can [link to it directly](https://gitea.scubbo.org/scubbo/blogContent/commit/9f98583f26b9ac0f5b8da53fe411fd9ca239232a)
[^2]: Future-Jack is here with the [retroactive-linking](https://gitea.scubbo.org/scubbo/blogContent/src/commit/9f98583f26b9ac0f5b8da53fe411fd9ca239232a/blog/layouts/_default/single.html#L50-L52)