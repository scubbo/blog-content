---
title: "MTG MCP 2"
date: 2025-10-07T22:01:56-07:00
tags:
  - AI
  - MTG

---
Another day, another instance of tinkering with my [Magic: The Gathering MCP Server]({{< ref "/posts/mtg-mcp" >}}).
<!--more-->
I wrote a [script](https://github.com/scubbo/mtg-mcp/blob/main/scripts/source-rules.py) to pull and index the Comprehensive Rules, and a few MCP tools to [get the index](https://github.com/scubbo/mtg-mcp/blob/main/lib/tools/get-rules-index.ts), [get a particular rule](https://github.com/scubbo/mtg-mcp/blob/main/lib/tools/get-rule.ts)[^grouped], or [look up a glossary term](https://github.com/scubbo/mtg-mcp/blob/main/lib/tools/get-glossary-term.ts), and that's it - no pre-seeding the LLM with any knowledge (besides whatever it already has in training already). I asked my Magic group for some questions to evaluate it with, and the results were super-impressive:

# Evals

## Basic test

```
> Give me a brief description of how the stack works in Magic: The Gathering. Do not go into
detail.

⏺ local-scryfall - get_glossary_term (MCP)(term: "Stack")
  ⎿ A zone. The stack is the zone in which spells, activated abilities, and triggered abilitie
    s wait to resolve. See rule 405, “Stack.”


⏺ local-scryfall - get_rule (MCP)(rule_number: "405")
  ⎿ 405.1. When a spell is cast, the physical card is put on the stack (see rule 601.2a). When
     an ability is activated or triggers, it goes on top of the stack without any card associa
    ted with it (see rules 602.2a and 603.3).
    … +41 lines (ctrl+o to expand)



⏺ The stack is a zone where spells and abilities wait to resolve. When you cast a spell or
  activate/trigger an ability, it goes on top of the stack. When all players pass priority in
  succession, the top item resolves. The stack uses "last in, first out" ordering—the most
  recently added spell or ability resolves first.
```

Can't argue with that!

## Crew copying

```
> If I give myriad to a crewed behicle, do those copies still count as artifacts I control?

⏺ local-scryfall - get_glossary_term (MCP)(term: "Myriad")
  ⎿ Myriad is a triggered ability that effectively lets a creature attack in all possible directions. See
     rule 702.116, “Myriad.”


⏺ local-scryfall - get_glossary_term (MCP)(term: "Vehicle")
  ⎿ An artifact subtype. Vehicles can become artifact creatures. See rule 301, “Artifacts,” and rule 702.
    122, “Crew.”


⏺ local-scryfall - get_rule (MCP)(rule_number: "702.116")
  ⎿  Error: Invalid rule number format. Please provide a 3-digit rule number (e.g., "100", "205", "701")

⏺ local-scryfall - search_cards (MCP)(query: "o:myriad", limit: 1)
  ⎿  Found 32 cards matching "o:myriad" (showing 1):

     1. **Auton Soldier**
     … +6 lines (ctrl+o to expand)

⏺ local-scryfall - search_cards (MCP)(query: "o:\"myriad\" o:\"attacking\"", limit: 3)
  ⎿  Found 1 cards matching "o:"myriad" o:"attacking"" (showing 1):

     1. **Elturel Survivors**
     … +6 lines (ctrl+o to expand)

⏺ local-scryfall - lookup_card (MCP)(name: "Elturel Survivors")
  ⎿  **Elturel Survivors**
     Cost: {3}{R}
     Type: Creature — Tiefling Peasant
     … +8 lines (ctrl+o to expand)

⏺ local-scryfall - get_rule (MCP)(rule_number: "707")
  ⎿ 707.1. Some objects become or turn another object into a “copy” of a spell, permanent, or card. Some
    effects create a token that’s a copy of another object. (Certain older cards were printed with the ph
    rase “search for a copy.” This section doesn’t cover those cards, which have received new text in the
    … +234 lines (ctrl+o to expand)



⏺ Yes, the token copies would be artifacts you control. However, they won't be creatures—crewing is a
  type-changing effect that doesn't get copied (per rule 707.2). The tokens copy only the printed
  characteristics of the vehicle (Artifact — Vehicle), not its temporary creature status. Since
  non-creatures can't attack, the myriad tokens won't actually be able to enter attacking, even though
  myriad tries to create them that way.
```

Note that it breezed through my typo in the input - impressive!

At this point, I didn't have guidance on the `get-rule` tool to just use the top-level rule number[^top-level], so it tried-and-failed to request "rule 702.116". Using the [existing tools for card lookup]({{< ref "/posts/mtg-mcp" >}}), though, it was able to figure out what Myriad does - and not only give an accurate answer, but also to anticipate what about that situation was unexpected and to address _that_ as well.

## Pro ~~Tour~~ Tier

```
> Amy controls The Gitrog Monster. On Amy's Upkeep, Brett casts Merfolk Trickster, which enters and targets the
Gitrog (the ability resolves). In her main phase, AMy casts Peer Into The Abyss, targetting herself;
Brett responds with Time Stop, which successfully resolves. Amy currently has 10 cards in hand -
9 lands and an Emrakul, the Aeons Torn. What happens at the end of turn?

⏺ local-scryfall - lookup_card (MCP)(name: "The Gitrog Monster")
  ⎿  **The Gitrog Monster**
     Cost: {3}{B}{G}
     Type: Legendary Creature — Frog Horror
     … +7 lines (ctrl+o to expand)

⏺ local-scryfall - lookup_card (MCP)(name: "Merfolk Trickster")
  ⎿  **Merfolk Trickster**
     Cost: {U}{U}
     Type: Creature — Merfolk Wizard
     … +5 lines (ctrl+o to expand)

⏺ local-scryfall - lookup_card (MCP)(name: "Time Stop")
  ⎿  **Time Stop**
     Cost: {4}{U}{U}
     Type: Instant
     … +4 lines (ctrl+o to expand)

⏺ local-scryfall - lookup_card (MCP)(name: "Emrakul, the Aeons Torn")
  ⎿  **Emrakul, the Aeons Torn**
     Cost: {15}
     Type: Legendary Creature — Eldrazi
     … +7 lines (ctrl+o to expand)

⏺ local-scryfall - get_rule (MCP)(rule_number: "719")
  ⎿  719.1. Each Case card’s illustration is vertically oriented on the left side of the card, and its type line is along the bottom of the card.
     719.2. The Case frame has no additional rules meaning.
     719.3. Case cards have two special keyword abilities that appear before a long dash and represent a triggered ability and an ability that may be static, triggered, or activated.
     … +5 lines (ctrl+o to expand)
  ⎿  1. Game Concepts
     100. General
     101. The Magic Golden Rules
     … +152 lines (ctrl+o to expand)

⏺ local-scryfall - get_rule (MCP)(rule_number: "723")
  ⎿ 723.1. Some cards end the turn. When an effect ends the turn, follow these steps in order, as they differ from the normal process for resolving spells and abilities (see rule 608, “R
    esolving Spells and Abilities”).
    723.1a If there are any triggered abilities that triggered before this process began but haven’t been put onto the stack yet, those abilities cease to exist. They won’t be put onto t
    … +23 lines (ctrl+o to expand)



⏺ local-scryfall - get_rule (MCP)(rule_number: "514")
  ⎿ 514.1. First, if the active player’s hand contains more cards than their maximum hand size (normally seven), they discard enough cards to reduce their hand size to that number. This
    turn-based action doesn’t use the stack.
    514.2. Second, the following actions happen simultaneously: all damage marked on permanents (including phased-out permanents) is removed and all “until end of turn” and “this turn” e
    … +7 lines (ctrl+o to expand)


⏺ During cleanup step:

  1. Discard phase (514.1): Amy discards 3 cards to reach max hand size. The Gitrog Monster still has no abilities (Merfolk Trickster's effect hasn't ended yet), so even if Amy discards
  lands, Gitrog won't trigger.
  2. End effects (514.2): "Until end of turn" effects end simultaneously with damage removal. Gitrog regains its abilities, but lands are already in the graveyard, so no trigger occurs.
  3. Check for triggers (514.3a):
    - If Amy discarded only lands/spells (not Emrakul): No triggers occurred. Turn ends.
    - If Amy discarded Emrakul: Emrakul's trigger (from step 1) goes on stack. Amy gets priority, trigger resolves shuffling her graveyard into library. Another cleanup step begins where
  Amy has 7 cards and no further discarding is needed. Turn then ends.

  Key point: The Gitrog Monster won't trigger regardless of what's discarded, because it lacks its triggered ability at the moment Amy discards (514.1), and only regains it after
  discarding is complete (514.2).
```

(Not sure why it tried looking up rule 719 :shrug:)

I was _pretty_ sure that it gave the corect answer, but doubted myself a little. In fact, at one point I thought "_wait, if Amy discards Emrakul **first**, wouldn't she have to discard in the second cleanup?_", before remembering that all discard is simultaneous.

But wait - LLMs are famously conciliatory and unwilling to push back. Maybe I can exploit that to get an incorrect answer...

```
> What if Amy discards Emrakul before discarding the other two lands?

⏺ The order doesn't matter. All discarding happens during the same step (514.1), before "until end of turn" effects end in step 514.2.

  Whether Amy discards Emrakul first, last, or in the middle, all three cards are discarded while The Gitrog Monster still lacks its abilities (Merfolk Trickster's effect hasn't ended yet). The Gitrog
   Monster only regains its triggered ability in step 514.2, after all discarding is complete.

  The result is the same: only Emrakul's trigger occurs, shuffling Amy's graveyard into her library, then a second cleanup step happens where no further discarding is needed.
```

...damn. People should really be looking into this AI stuff, I bet it's going to be big one day...[^control]

# Next Steps

I'm still pretty interested in setting up a Rules Lawyer bot for my group's Discord - either that, or setting up some kind of automated eval where I:
* Auto-transcribe [JudgingFTW's videos](https://www.youtube.com/@JudgingFtW)
* Extract a "question" and an "answer"
* Put the question to a model with these MCP tools, and evaluate the answer for correctness

[^grouped]: For simplicity, I grouped all sub-rules together - so, if you wanted `705.2a`, the LLM will have to just request the text for `705` and parse through it - but at the scale I'm dealing with, that amount of extra context shouldn't be a problem, I guess? More-efficient indexing would improve performance if necessary.
[^top-level]: If any AI gurus are reading this, I'm curious - is there a cost associated with putting detailed usage instructions in MCP tool descriptions? Does it use up extra context?
[^control]: As a control group, I tried asking these same questions to `claude` without the MCP. It was able to describe the Stack correctly, and answered the second question basically (but without the extension part). On the Gitrog Monster question it made the expected error of assuming that the GM regained its ability before discard, and [ChatGPT makes the same mistake](https://chatgpt.com/c/68e5f735-b758-8328-bfd3-b02f61c99ff2).