---
title: "MTG MCP"
date: 2025-07-30T20:41:59-07:00
tags:
  - AI
  - MTG
  - Vercel

---
I just built my first MCP[^whats-mcp] Server, and it was awesome.
<!--more-->
([Here's](https://github.com/scubbo/mtg-mcp/) the code, if you're that way inclined)

I was tinkering with my new [Kilo](https://archidekt.com/decks/14275422/kilo) deck, and figured I should add a bit more removal; I already had [Shinewend](https://scryfall.com/card/mor/23/shinewend) and [Stingmoggie](https://scryfall.com/card/mor/106/stingmoggie) in there for Enchantment and Artifact removal, respectively[^land-destruction], but some creature removal would be nice. I _could_ probably figure out the Scryfall search syntax for "_a thing that removes counters to destroy creatures_", but this was a great opportunity to tinker with new technology.

I didn't start out planning to use MCP - I've been using [Claude Code](https://www.anthropic.com/claude-code) as a coding assistant recently, and although it's optimized for software, I've been impressed at how it can integrate web searches to gather more information. So I gave it a shot:

```
> What's an equivalent of Stingmoggie or Shinewend, but for creatures?

⏺ I'm not familiar with "Stingmoggie" or "Shinewend" - could you provide more context about what these are? Are
  they from a specific game, book, fictional universe, or naming system? Understanding what they represent would
   help me suggest creature equivalents.

> They're cards from Magic The Gathering

⏺ Ah, Magic: The Gathering cards! Both Stingmoggie and Shinewend are artifact/enchantment removal spells that
  sacrifice themselves to destroy a target.

  For creatures with similar effects, you'd want creatures that can destroy artifacts or enchantments, either
  when they enter the battlefield or through activated abilities. Some examples:

  - Reclamation Sage - Destroys target artifact or enchantment when it enters
  - Acidic Slime - Destroys target artifact, enchantment, or land when it enters
  - Thrashing Brontodon - Sacrifice it to destroy target artifact or enchantment
  - Qasali Pridemage - Sacrifice it to destroy target artifact or enchantment
  - Viridian Zealot - Sacrifice it to destroy target artifact or enchantment

  These creatures give you the same removal effect but leave behind a body, making them generally more versatile
   than the direct spell equivalents.

> "Both Stingmoggie and Shinewend are artifact/enchantment removal spells that sacrifice themselves" - are you
  sure about that? Check again

⏺ You're right to question that - I should be more careful about my Magic knowledge. I'm not certain about the
  exact mechanics of Stingmoggie and Shinewend without being able to verify the card details.

  Could you remind me what these cards actually do? That way I can give you a more accurate suggestion for
  creature equivalents.
```

Uh oh - not great. Time to give it more context!

I knew that Vercel had a solid [Getting Started with MCP](https://vercel.com/docs/mcp) document that I'd previously used to kick the wheels - I used that as a starting point, then used Claude to vibe-code my way to adding tools for `lookup_card`, `random_card`, `search_cards`, and `search_syntax_guide`. Being able to just say "_look at the docs at this URL, then implement it as a tool_", and have it work first time, was the closest thing to magic I've ever experienced as a software developer.

After less than an hour[^timespan], I had what appeared to be a complete implementation up and running. After running `claude mcp add --transport http local-scryfall http://localhost:3000/api/mcp` to register the server with Claude, I gave it a shot:

```
> First, look up the Magic cards Stingmoggie and Shinewend. Then, determine what special property they have in common (you can look up
  random Magic cards to get context for what other cards are like - look for what makes Stingmoggie and Shinewend special). Finally, find
   me a card that does what they do, but for creatures.

⏺ I'll help you explore these Magic cards and find what makes them special. Let me start by looking up Stingmoggie and Shinewend, then
  find their common property.

⏺ Update Todos
  ⎿  ☐ Look up Stingmoggie card details
     ☐ Look up Shinewend card details
     ☐ Find a card that does what they do but for creatures
     ☐ Analyze common properties between the two cards
     ☐ Look up random cards for context on typical Magic card properties

⏺ local-scryfall - lookup_card (MCP)(name: "Stingmoggie")
  ⎿  **Stingmoggie**
     Cost: {3}{R}
     Type: Creature — Elemental
     … +5 lines (ctrl+r to expand)

⏺ local-scryfall - lookup_card (MCP)(name: "Shinewend")
  ⎿  **Shinewend**
     Cost: {1}{W}
     Type: Creature — Elemental
     … +6 lines (ctrl+r to expand)

⏺ Update Todos
  ⎿  ☒ Look up Stingmoggie card details
     ☒ Look up Shinewend card details
     ☐ Analyze common properties between the two cards
     ☐ Find a card that does what they do but for creatures
     ☐ Look up random cards for context on typical Magic card properties
  ⎿  **Murmurs from Beyond**
     Cost: {2}{U}
     Type: Instant — Arcane
     … +4 lines (ctrl+r to expand)
  ⎿  **Sunken Hollow**
     Cost: N/A
     Type: Land — Island Swamp
     … +4 lines (ctrl+r to expand)
  ⎿  **Meteor Golem**
     Cost: {7}
     Type: Artifact Creature — Golem
     … +4 lines (ctrl+r to expand)

⏺ Update Todos
  ⎿  ☒ Look up Stingmoggie card details
     ☒ Look up Shinewend card details
     ☒ Analyze common properties between the two cards
     ☒ Look up random cards for context on typical Magic card properties
     ☐ Find a card that does what they do but for creatures

⏺ local-scryfall - search_cards (MCP)(query: "o:\"remove a +1/+1 counter\" o:\"destroy target creature\"", limit: 10)
  ⎿  Found 1 cards matching "o:"remove a +1/+1 counter" o:"destroy target creature"" (showing 1):

     1. **Suncrusher**
     … +6 lines (ctrl+r to expand)

⏺ local-scryfall - lookup_card (MCP)(name: "Suncrusher", exact: true)
  ⎿  **Suncrusher**
     Cost: {9}
     Type: Artifact Creature — Construct
     … +6 lines (ctrl+r to expand)

⏺ Update Todos
  ⎿  ☒ Look up Stingmoggie card details
     ☒ Look up Shinewend card details
     ☒ Find a card that does what they do but for creatures
     ☒ Analyze common properties between the two cards
     ☒ Look up random cards for context on typical Magic card properties

⏺ Special Property: Both Stingmoggie and Shinewend are 0/0 creatures that enter with +1/+1 counters and can sacrifice those counters to
  destroy permanents. This is unusual - most creatures either have natural power/toughness or destroy things when they enter the
  battlefield, not through activated abilities that consume their own stats.

  Common Pattern:
  - Both are 0/0 creatures that depend entirely on +1/+1 counters to survive
  - Both have activated abilities that remove their own +1/+1 counters to destroy specific permanent types
  - Stingmoggie destroys artifacts or lands
  - Shinewend destroys enchantments

  Answer: Suncrusher does what they do but for creatures. It's a 3/3 artifact creature with Sunburst that enters with +1/+1 counters, and
   has the activated ability "{4}, {T}, Remove a +1/+1 counter from this creature: Destroy target creature."

> Nice! Is there anything that can remove a different kind of counter (or, any kind of counter) to destroy a creature?

⏺ local-scryfall - search_cards (MCP)(query: "o:\"remove a\" o:\"counter\" o:\"destroy target creature\"", limit: 15)
  ⎿  Found 3 cards matching "o:"remove a" o:"counter" o:"destroy target creature"" (showing 3):

     1. **Otherworldly Escort**
     … +19 lines (ctrl+r to expand)

⏺ local-scryfall - lookup_card (MCP)(name: "Transmogrifying Wand", exact: true)
  ⎿  **Transmogrifying Wand**
     Cost: {3}
     Type: Artifact
     … +5 lines (ctrl+r to expand)

⏺ local-scryfall - search_cards (MCP)(query: "o:\"remove\" o:\"counter\" o:\"destroy\" NOT o:\"+1/+1\"", limit: 10)
  ⎿  No cards found matching query: "o:"remove" o:"counter" o:"destroy" NOT o:"+1/+1""

⏺ Yes! Transmogrifying Wand removes charge counters (not +1/+1 counters) to destroy creatures. It enters with three charge counters and
  has the ability: "{1}, {T}, Remove a charge counter from this artifact: Destroy target creature. Its controller creates a 2/4 white Ox
  creature token."

  This gives the destroyed creature's controller compensation, unlike the previous examples that were straight destruction.

> Looks like you found some other cards from that search (Otherwordly Escort and another one) - what were they?

⏺ local-scryfall - lookup_card (MCP)(name: "Otherworldly Escort", exact: true)
  ⎿  **Otherworldly Escort**
     Cost: {3}{W}
     Type: Creature — Human Detective
     … +7 lines (ctrl+r to expand)

⏺ The three cards from the search were:

  1. Otherworldly Escort - Uses charge counters (not +1/+1 counters) to destroy creatures, but only creatures that dealt damage to you
  this turn. When it dies, it returns as a Spirit with four charge counters.
  2. Suncrusher - The one we already found that uses +1/+1 counters.
  3. Transmogrifying Wand - Uses charge counters as we discussed.

  So Otherworldly Escort is another example that uses charge counters instead of +1/+1 counters, though it has the restriction of only
  targeting creatures that damaged you.
```

Freaking _wild_.

The code may not be perfect - there's a fair bit of duplication of the "_communicate with Scryfall_" parts, there's still some extraneous Next.js-y stuff in `app/*.tsx`, and of course it's lacking any auth or similar - but for something that I could have mocked-up while watching a TV episode, this is _breathtaking_.

I think I'm already on record as saying this, but, for the avoidance of doubt - my opinion on AI tools has done a _full_ 180 in the last six months or so. From being "_annoyingly unreliable, to the point that you spend more time and effort baby-sitting them than they save you_", they've become genuinely powerful leverage tools. And at the current rate of acceleration, I can't imagine what we'll be seeing in a year's time. The concerns about energy use, accumulation of wealth to capital-holders, and IP infringement/artistry devaluation still exist; but boy oh boy, I will never again make the claim that they're not _powerful and useful_ tools.

...Sadly, [Suncrusher](https://gatherer.wizards.com/5DN/en-us/159/suncrusher)'s ability requiring it to tap means it's probably not as good as [Triskelion](https://scryfall.com/card/moc/387/triskelion), which can also function as Player Removal. Ah well!

[^whats-mcp]: [Model Context Protocol](https://modelcontextprotocol.io/docs/getting-started/intro) is "_an open protocol that standardizes how applications provide context to large language models (LLMs)_". It's essentially an API syntax allowing LLMs to interface with other systems - MCP servers can list the "tools" that are available to an LLM, and provide a standardized way for it to use them.
[^land-destruction]: Friends don't let friends destroy lands.
[^timespan]: And that was with plenty of distraction - I think I could have got it done in 15 minutes if I'd have been focused

<!--
Reminders of patterns you often forget:

Images:
![Alt-text](url "Caption")

Internal links:
[Link-text](\{\{< ref "/posts/name-of-post" >}})
(remove the slashes - this is so that the commented-out content will not prevent a built while editing)
-->