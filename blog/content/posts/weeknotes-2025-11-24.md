---
title: "Weeknotes 2025-11-24"
date: 2025-11-24T20:02:46-08:00
tags:
  - Weeknotes

---
A little bit later than I intended, but...still counts!
<!--more-->
# What I Did

## Work

Things are feeling a _lot_ less stressed - in every sense of the word. I had a 1:1 with my mentor where I did the scary vulnerable thing of asking "_hey, this person who appeared to **me** to be competently delivering was abruptly fired, and it made me feel insecure about my own position here. What can you tell me about that?_". Obviously I won't share the details of that conversation here; but suffice it to say that I got reassurance that - although some of my concerns about my _delivery_ are well-founded - my job _security_ is solid[^secure], especially if I keep soliciting and taking feedback. So - I think we're golden there!

Weirdly, my anxiety has now flipped to having too _little_ direction - "_no-one's told me what to be working on, and the project I'm currently on doesn't seem to be directly related to the team's goals, even though plenty of people are clamouring for it, so...how will my performance be evaluated if I keep on on this?_". Trying to embrace what seems to be the Vercellian way and Just Do (The) Things (That I Think Are Right) :/

## Personal

### Agentic development

Having tricked out my gaming PC with egregious RAM and CPU to go along with the GPU, I experimented with writing my own chat agent that could use an LLM and MCP tools in a loop, and it went...not great...

![AI Agent stuck in a loop](/img/ai-agent.png "AI agent stuck in a...flesh-loop?")

A little bit of probing suggested that the responses of the tool calls were themselves being sent back to the LLM for response, triggering the loop. I switched gears to writing a logging-proxy that is now sitting between an existing tool and my LLM, so I can inspect them for good practices and see what I should be implementing. Interesting challenge!

I also added some availability monitoring to my homelab

![Uptime Monitoring](/img/availability-monitoring.png)

And finally, made it to what I'm pretty sure is either the final or penultimate boss of Silksong. Beautiful game - not without flaws, but they're minor in the grand scheme of things. Very much looking forward to 100%-ing this, and even more so to the inevitable Godseeker-esque DLC.

# What I Hope To Do

## Work

Finally ship some value with this project, then figure out whether it will be better to keep working on it or to do something else. Very deliberate choice of words there - my instincts were to put "_whether I should_", but the theme I'm both sensing and embracing here is self-directed work. Let's do it!

## Personal

* Finish Silksong - and, heck, I'm probably not far from completing Factorio Space Age at this point, either. It's a short work-week what with Thanksgiving...should be doable!
* Backups of my HA Cluster Postgres (like I promised to [here](https://blog.scubbo.org/posts/a-new-start/#next-priorities)), alongside some kind of alerting system to plug into those availability monitors.

[^secure]: Or, well, y'know - as secure as it ever can be under ~~ruthless~~ rugged capitalism.
