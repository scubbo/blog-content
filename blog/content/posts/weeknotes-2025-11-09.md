---
title: "Weeknotes 2025-11-09"
date: 2025-11-09T15:52:42-08:00
tags:
  - Weeknotes

---
So much for consistency. Forgive me Internet, for I have sinned - it has been five months since my last weeknotes.
<!--more-->
In my defence, I've been a little busy over the last 10 weeks or so welcoming a new family member:

![Bumi1](/img/bumi-1.jpg)

![Bumi2](/img/bumi-2.jpg)

![Bumi3](/img/bumi-3.jpg)

His name is Bumi, and he is my perfect precious baby who can do no wrong.

Pup parenthood has been a wild ride. My therapist is delighted with how it's forced me to accept help rather than soldiering on independently, and to realize that it's not an imposition on other people to accept what they offer. Truth be told I was a little nervous about getting a pug as to me they've always looked kind-of ugly, but within half a second of holding him for the first time I fell completely in love.

Bumi's been the majority of my personal life for most of that time, though I did manage to get my D&D campaign restarted recently and to host another instance of my regular board games event early-on. Tech-wise, I've made a bunch of improvements to my Magic group's game tracking website; and professionally, there's been some big shake-ups in what my team is meant to be focusing on, so it looks likely that my project of the last few months has a hard timelimit - "_show some value by next week or get cancelled_". I've had some good guidance from my mentor on how best to cut scope to achieve that - here's hoping we can ship _something_.

Oh, one other thing I forgot - after getting irritated at how my k3s cluster could no longer automatically start because it relied on a Postgres database, I finally delved into learning enough `systemd` to define that startup. Turns out it's really easy - just:

```
# /etc/systemd/system/k3s-postgres-docker.service
[Unit]
Description=Start the Postgres Docker Container that supports k3s cluster
After=docker.service
Requires=docker.service

[Service]
Type=simple
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
WorkingDirectory=/home/scubbo/k3s-ha-postgres
```

and then adding
```
Wants=k3s-postgres-docker.service
After=k3s-postgres-docker.service

```

in the `k3s` service's own definition file. Easy peasy!

<!--
Reminders of patterns you often forget:

Images:
![Alt-text](url "Caption")

Internal links:
[Link-text](\{\{< ref "/posts/name-of-post" >}})
(remove the slashes - this is so that the commented-out content will not prevent a built while editing)
-->
