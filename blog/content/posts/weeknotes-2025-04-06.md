---
title: "Weeknotes: 2025-04-06"
date: 2025-04-06T21:50:46-07:00
tags:
  - CI/CD
  - Gitea
  - Vault
  - Weeknotes

---
Looks like I'm averaging about one "weeknotes" post every two weeks. That's actually not too bad!
<!--more-->
Continuing from my [previous post]({{< ref "/posts/weeknotes-the-third" >}}), I did install the [GitHub Vault Plugin](https://github.com/martinbaillie/vault-plugin-secrets-github) on my Vault, but then I got side-tracked to shaving a _different_ yak - Gitea provides no OIDC token for Gitea Actions, so it's not possible to create a different Vault Role for each repo's actions in order to maintain least-privileges. Instead, I've created a single Vault Role that is accessible (to _every_ repo's Actions) via the `kubernetes` [auth method](https://github.com/hashicorp/vault-action?tab=readme-ov-file#kubernetes). Which is, honestly, _fine_ for this setup (where I'm the owner of all the repos on the forge and so I don't have to worry about permission issues from untrusted actors) - but it's not _right_, dammit!

Thankfully, the bulk of the work of adding OIDC tokens to Gitea Actions had already been completed [nearly two years ago](https://github.com/go-gitea/gitea/pull/25664), but the original author had lost motivation and the PR was abandoned. Both GoLang (the language in which Gitea is written) and OIDC/JWT are things that I am _moderately_ familiar with, albeit no expert - but, that's enough to have [forked the PR and tried to keep moving it forward](https://github.com/go-gitea/gitea/pull/33945)! I'd be really psyched to get this change merged - even though I didn't author the original change, it would still feel great to help contribute this sizeable feature to an Open Source project that I use and respect. Getting PRs merged is [Glue Work](https://www.noidea.dog/glue), and that's still valuable!

Other than that:
* I've been enjoying playing around with [Vercel](https://vercel.com/home)/[Next.js](https://nextjs.org/) after a highly-respected ex-colleague recommended them (hi Dustin!)
* I've put a bit more effort into "EDH ELO", the [webtool I've been tinkering with](https://gitea.scubbo.org/scubbo/edh-elo) to rank my Magic: The Gathering Commander playgroup's decks from match results. Kinda tempted to combine the two and "_Rewrite It In ~~Rust~~React_" :P

<!--
Reminders of patterns you often forget:

Images:
![Alt-text](url "Caption")

Internal links:
[Link-text](\{\{< ref "/posts/name-of-post" >}})
(remove the slashes - this is so that the commented-out content will not prevent a built while editing)
-->