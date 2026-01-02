---
title: "2025 Wrap Up Articles"
date: 2026-01-01T17:50:55-08:00
tags:
  - End-of-Year-Wrapups
  - Reading

---
Standout articles I read this year
<!--more-->

# Articles

## [The "Rice Knuckle Rule" Rule](https://www.atvbt.com/the-rice-knuckle-rule-rule/)

"_People filter their own self-perception through beliefs and preconceptions, so will often _believe_ that they are consistently following rules or guidelines when in fact those rules are being (productively!) twisted-to-fit the situation. Which is fine; except when they try claiming that the rule is factual, ironclad, and should apply to everyone._"

Shared by [George](https://bsky.app/profile/thewizardlockwood.bsky.social) the preceding December. The idea of using local knowledge to complete a task the best way, rather than the "right" way, evokes the contrast between _techne_ and _metis_ from Seeing Like A State.


## [Blub Work](https://www.benkuhn.net/blub/)

Gives a name to "_the boring, everyday, grindy skills that don't feel flashy or impactful_" - e.g. learning how Git works - and making the claim that it is worthwhile as a foundation for higher-level skills. I wonder how relevant Blub Work will continue to be in the age of ascending AI assistants.

## [The Juggler's Curse](https://buttondown.com/hillelwayne/archive/the-jugglers-curse/)

"_Once you achieve a particular level of competency in a discipline, it no longer seems challening, so it's easy to feel as if you're no longer making progress. Conversely, when considering tasks that are outside your ability, they all seem equally impossible, because you don’t have the skill or context to be able to differentiate them_"

## [3 Tribes of Programming](https://josephg.com/blog/3-tribes/)

"_Poets, hackers, and makers; those who use programming to express thought, those who delight in making a computer do things, and those who focus on the end results_".

Crucially - none of them are entirely right, and none of us are entirely one of them. But identifying which camp we're arguing from can help resolve disagreements.

## [14 Advanced Python Features](https://blog.edward-li.com/tech/advanced-python-features/)

I have a _great_ deal of affection for Python. Aside from the weird choice to make `map`/`filter` non-chainable (which can be fixed with [`toolz:pipe`](https://github.com/pytoolz/toolz) or [`fn.py`](https://github.com/kachayev/fn.py)), it all just feels right and comfortable to me as the most efficient language in which to express thought.

I've never understood the common complaint about Python's packaging - I've had far far more issues with JavaScript where I've had to completely blow away a `node_modules` or `pnpm-lock.yaml` and restart, or had to dive into the various esoteric ways to invoke ESM or CJS, than I have with `pip install -r requirements.txt` (or, better yet, [`uv run`](https://docs.astral.sh/uv/guides/tools/)). "_Python's type system is optional_" is an absurd criticism - what they really mean is, "_running Python's type-checker is an explicit command rather than part of a native build process_", but so is running tests[^types-are-tests] in most languages and we don't criticize them for that.

Lots of lovely tools in here - many of which would probably be overkill for daily use, but would be a godsend the one time you need them.

## [Accountability Sinks](https://250bpm.substack.com/p/accountability-sinks)

([HN](https://news.ycombinator.com/item?id=43877301))

A discussion of a [book](https://www.amazon.com/Unaccountability-Machine-Systems-Terrible-Decisions/dp/0226843084), "_The Unaccountability Machine: Why Big Systems Make Terrible Decisions — and How the World Lost Its Mind_", which observes that inhuman formal structured processes, although often improving efficiency and safety (checklists!) and instutional memory, result in brittle or inflexible processes when unexpected situations arise. Seeing Like A State rears its head once more!

This ties in well to a mindset change that I want to cultivate in 2026: reducing my excessive dislike for rule-breaking in-and-of-itself, and recognizing that - in the face of an incomplete, outdated, or unhelpful process - it's better to do the right thing _and then_ to change (or do away with) the process.

---

Also, HN comments led me to the concept of an [asshole filter](https://siderea.dreamwidth.org/1209794.html) - if your system is designed such that only rude people get satisfaction, then the system will encounter more rude people.

## [Experts Have It Easy](https://boydkane.com/essays/experts)

"_Experts subconciously avoid pitfalls and fill in missing parts of guides or documentation, meaning they consistently under-estimate the complexity of tasks for beginners_". Ties into the [Blue Tape List](https://randsinrepose.com/archives/the-blue-tape-list/) (new hires are the best reviewers of your processes and documentation, because they haven't yet learned "how things work"), and the Juggler's Curse above

## [My AI Skeptic Friends Are All Nuts](https://fly.io/blog/youre-all-nuts/)

([HN](https://news.ycombinator.com/item?id=44163063))

Makes a convincing case that all arguments against the utility of AI tools are moot, ill-founded, or in bad faith (and further, undermines most ethical arguments).

Fittingly, I read this around the time that my opinion on these tools was beginning to undergo a sea change. This, and [Simon Willison](https://simonwillison.net/), take most of the credit for getting me to be open-minded in trying again.

## [Face It; You're A Crazy Person](https://www.experimental-history.com/p/face-it-youre-a-crazy-person)

([HN](https://news.ycombinator.com/item?id=44710651))

"_Most poeple's conceptions of careers do not account for their day-to-day mundanity, making it hard to pick a career you'll actually enjoy. People also tend to underecognize the ways in which they are unique or unusual (which could be good predictors of career suitability)_"

I particularly like the positive encouragment to "_actively shape your life_" in this. Another article on that which didn't make the cut was [If you don't design your career, someone else will](https://gregmckeown.com/if-you-dont-design-your-career-someone-else-will/) ([HN](https://news.ycombinator.com/item?id=46352930)).

## [The Gap Through Which We Praise The Machine](https://ferd.ca/the-gap-through-which-we-praise-the-machine.html)

Highlighting the difference between Work As Imagined and Work As Done (or, I guess, "LLMs As Imagined" and "LLMS As Used"), and the frustration for newbies because old hands have subconciously adapted to the tool. This leads to "newbie-blaming" when the tool doesn't conform to an input that's is reasonable to an outsider.

This was a big component of my anti-AI feelings for a while. The goalposts seemed to be continually moving - these tools were simultaneously industry-upending marvels that could perform superhuman feats and were tearing down accessibility barriers to programming, while also being fragile inscrutable mysteries that required obscure rituals and practices to operate.

## [Altoids By The Fistful](https://www.scottsmitelli.com/articles/altoids-by-the-fistful/)

Creative writing, observing (in my interpretation) that AI tools can smooth over much of the pointless frustrations of Actually Getting Work Done, with a tangent into recognizing the gate-keeping that tech nerds tend to impose on those whho have not Suffered As They Suffered.

## [Seeing Like A Software Company](https://www.seangoedecke.com/seeing-like-a-software-company/)

"_The principles of legibility (and fungibility and predictability) that apply to states impose on their subjects are the same principles many software companies impose on their employees' work_"

You already know I'm a sucker for anything "Seeing Like A State"-shaped, and this didn't disappoint.

Another article that directly ties into a mindset change I want to make in myself in the coming year[^sociopath]. Quoting directly from the conclusion:

> * Breaking the (formal, legible) rules is sometimes the right thing to do
> * Competent engineers should work on “side bets” that are outside the normal planning process

## [How Good Engineers Write Bad Code At Big Companies](https://www.seangoedecke.com/bad-code-at-big-companies/)

([HN](https://news.ycombinator.com/item?id=46082223))

"_Answer: they're mostly patching changes onto code they didn't write, written by people who were not incentivized to document it, and **the company - an economic entity - often (rightly) prioritizies speed over quality**_"

Heh, I didn't notice until just now that this and the prior one were written by the same person.

## [Simon Willison's 2025 recap](https://simonwillison.net/2025/Dec/31/the-year-in-llms/)

A slight cheat, as I read this today - but it makes sense to include it here.

# Noted patterns

A few through-lines I notice in these articles

* 4 (Rice Knuckle, Juggler's, Experts Have It Easy, You're A Crazy Person, TGTWWPTM) on "_people do not perceive themselves or their competency accurately_"
* 3 (Rice Knuckle, Blub Work, Juggler's Curse) on "_giving a name to a phenomenon so as to make it easier to talk about_"
* 3 (Rice Kunckle, Tribes, Experts Have It Easy) on how communication can break down because of unspoken assumptions
* 3 ("All Nuts", TGTWWPTM, Altoids, Simon's) on AI
* 2 (Rice Knuckle, Seeing Like A Software Company) on "_Systems do not actually work the way that they claim to_"
* 2 (3 Tribes, Good Engineers Write Bad Code) on "_the market rewards extant bad code over unreleased good code (and employers proxy-through rewards of the market)_" (to be fair, 3 Tribes doesn't itself hold this position - but the last tribe of engineers would)

[^types-are-tests]: Which makes sense, because types are tests
[^sociopath]: Before reading this article, I would have never expected to find myself saying "_I should become more of a sociopath_"
