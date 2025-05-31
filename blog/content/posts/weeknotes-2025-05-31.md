---
title: "Weeknotes: 2025-05-31"
date: 2025-05-31T12:25:33-07:00
tags:
  - AI
  - EDH-ELO
  - Vercel
  - Weeknotes

---
Written from the Oakland airport, on my way to L.A. to attend a live show of Dimension 20 with my good friend Patrick.

God, time has _flown_ by. Is this really the end of my fifth week at Vercel? Feels like a few days. That's a good sign, I suppose!
<!--more-->
# Work

That said, I've noted a tendency to work late the last couple weeks, with the intention of making sure I make a notable impact in my first few (higly-leveraged and impression-making) weeks at work. This is a trade-off that I'm consciously and deliberately making, and I'm alright with it; but I do want to keep an eye on it and make sure that it doesn't become a habit. As a wise woman once told me, "_work isn't real life_" - and work will naturally expand to fill all the time you give it. It's a gift to have a job that is compelling enough that you _want_ to spend time on it; but it's also important to me to focus on, and fence off time for, the other aspects of my life.

# All About AI

## Tool Use

The other day, I threw a personal project (an ELO tracker for Magic EDH decks) through Vercel's [v0](https://v0.dev/) tool, asking it to convert the website from Python to TypeScript (so I could use it as a testbed for experimenting with [Next.js](https://nextjs.org/) and the Vercel platform). The results were...alright, to be honest. Despite being given a link to the source code, it wasn't able to read the code, but instead just screenshotted the actual deployed site, and the resulting code was more of a generic "_EDH tracker_" than "_a translation of this particular site_" - some intentional specific design decisions were ignored (e.g. ELO score for a deck, not for a player), and the visual design looked completely different (admittedly - much _better_, but different!).

I spent an evening tweaking and shaping it with Claude-Sonnet-on-Cursor[^vo-api], and, honestly, the experience was a mix of inspiring and depressing. Inspiring with how much the tooling has improved in a couple years since I first tried it; depressing for two reasons:
* How obsolete my knowledge and experience will soon be. This is something I can realistically change and work on - adapting to learning a new skillset is a challenge, but a worthwhile one!
* How obsolete "_understanding of the underlying systems_" will soon be to the act of creation. This one's a little more complicated - I don't philosophically agree with anything which gatekeeps or obstructs the act of creation, but I'm also uncomfortable with a deliberate celebration of ignorant creation[^ownership]. Wiser minds than I have spilled miles of pixel-ink on how AI _amplifies experience_, with all that that implies about "_if you are inexperienced, it will amplify your inexperience_". Leaving aside any questions about whether AI will, in fact, "_take our jobs_" (my bet is - some, but not most), I do wonder about how _maintainable_ the outputs of Vibe Coding will be. Especially relevant as I've been coaching a friend through the process of learning coding in order to build a system to drive her own medical care, where the AI's positively encouraged her into some...interesting...choices (mostly, I suspect, driven by the tooling's complaisant agreeability). We shall see!

## Attitude

Driven by [this article](https://steveklabnik.com/writing/i-am-disappointed-in-the-ai-discourse/), I had an interesting realization - after Crypto and NFTs and Web3 (and probably others I've forgotten), I have adopted an irrationally-hostile perspective to _any_ claims about technology from any company. That is - if a corporation had tried telling me "_ChatGPT is able to search the web for new information, post-training_", I would simply assume that that was a lie. Even for a proud anti-corporatist, this isn't a healthy or productive mindset - it's a core value of mine to make sure that my criticisms are accurate and founded in fact, lest I undermine _legitimate_ critism by mixing it in with ill-informed supposition.

[^vo-api]: `v0`-in-Cursor is [coming soon](https://vercel.com/docs/v0/api), but currently only available for Enterprise customers.
[^ownership]: cf. the excellent article on [Broken Ownership](https://blog.alexewerlof.com/p/broken-ownership) - if you don't know how a thing works, you will be much less likely to be able to fix or change it
