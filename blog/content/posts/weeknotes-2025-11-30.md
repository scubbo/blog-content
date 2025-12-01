---
title: "Weeknotes 2025-11-30"
date: 2025-11-30T20:50:14-08:00
tags:
  - Weeknotes

---
# What I Did
<!--more-->
## Work

A short week this week for Thanksgiving. I got my current project to the point of doing a(n apparently-successful) Dry Run of a data migration on Wednesday afternoon, but (sadly? thankfully?) too late to get official confirmation/approval to start the Live Run over the Thanksgiving break. Hoping to get that kicked off on Monday, then to loop back and start adding usability features (including a UI) to onboard more users.

## Personal

### Tech

LLMs-as-coding-assistant continue to amaze and astound. On a whim on Saturday night, I decided I wanted to finish off a project I've been meaning to complete for ages - deploying my [`yt-dlp`](https://github.com/yt-dlp/yt-dlp)-as-a-service container to my homelab, so that I can just paste a URL to a convenient tool[^extension] to grab it. Not only was I able to throw that together in a few turns of conversation while simultaneously watching TV (and moderately high), but during deployment I was also able to shave _another_ yak I've been putting off - [automatically updating my DNS server for k8s Ingresses](https://github.com/scubbo/homelab-configuration/commit/2a060b77716d8be8406c70f8760f266bff6aee61), which itself involved a sub-agent invocation to ensure I was making the right choice between [VSO](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/vso) and [ESO](https://external-secrets.io/latest/). While I definitely needed to steer and give feedback, and I would technically have been able to implement all those steps myself, the responses were fast enough and of such good quality that the speed-up was significant. Practically speaking, this is the kind of multi-hour deep-dive that I would have kept procrastinating on forever, whereas now I could Just Do It. It even took [such copious notes along the way for my eventual blog post](https://github.com/scubbo/homelab-configuration/blob/main/docs/blog-post-notes-external-dns-opnsense.md) that I almost don't feel the need to expound on that. The times, they are a-changing.

I actually ran out of Claude Code Pro allowance during that implementation - spent a while looking for whether it was possible to point the Claude Code tool at a locally-hosted OpenAI-compatible backend, to which the answer _seems_ to be no, unfortunately. I fell back to Codex, which seemed of equivalent quality though lacked a lot of the [customization](https://github.com/scubbo/dotfiles/blob/master/.claude/CLAUDE.md) I've accumulated.

### Other

Went to a stupendous Thanksgiving feast hosted by my dear friends Sean and Deb.

Wedding-recelebration prep is kicking into higher gear. We have nearly everyting lined up and ready, last major decision is on the caterer (tastings coming up week after next), but we're crossing many Ts and dotting many Is along the way.

Got the "good ending" for Silksong, after 150 attempts at the boss, at 83% completion, taking 73h 17m 26s.

# What I Hope To Do

## Work

Get the Dry Run results confirmed, and start a Live Run, then start building more UI. Oh, and finally book the PTO and oncall cover for my wedding prep (tastings) and the day itself!

## Personal

[Advent Of Code](https://adventofcode.com/2025/) (and [SysAdmin](https://sadservers.com/advent)) are kicking off - given that the former has half the challenges this year, it might be more feasible to finally finish it! Might break my tradition of using a new-to-me language ([Rust](https://github.com/scubbo/advent-of-code-2023) and [Zig](https://github.com/scubbo/advent-of-code-2024), respectively) and just use TypeScript/Python in the interests of completion. AI-free, obviously - the challenge is the point, not mere completion.

I know I keep saying I'm going to get backups of the Postgres database for my HA cluster. It's the next thing, I swear...

I did toy with the idea of trying to complete Factorio: Space Age over this weekend to twofer two of my favourite games, but realized there's still a _significant_ chunk of content post-Aquilo (gotta adapt to biolabs first!), so...that'll keep me going for the rest of the year, at least! Plus I do wanna 100% Silksong.

[^extension]: Or, eventually, click a browser extension while on the appropriate page
