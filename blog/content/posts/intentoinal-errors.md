---
title: "Intentoinal Errors"
date: 2021-12-13T21:36:09-08:00
---

There's an [apocryphal story](https://rachelbythebay.com/w/2013/06/05/duck/) from the development of a game called Battle Chess. A Product Manager was well-known to _always_ have to make a comment or propose a change on anything, [no matter how minor](https://en.wikipedia.org/wiki/Law_of_triviality) - so, an engineer intentionally added an incongruous companion duck in a piece's animation. The PM could say "_looks good - but lose the duck_", and feel that they'd had a meaningful impact, when in fact the end result after removing the "sacrificial duck" was exactly as the engineer had originally intended.

There's a whole other blog post in there about the psychology of cooperative labour and the importance of feeling that you are contributing (which is increasingly hard as your role becomes more separated from the "coal face"), or about learning to work around observed behaviours of those with control in an organization (though, as a [Hacker News comment](https://news.ycombinator.com/item?id=9139639) points out - by indulging this kind of behaviour, you are probably incurring "Organizational Tech Debt" and not doing your manager any favours as their bad behaviour calcifies), but today I actually want to talk the different flavours of intentional error[^1]. You might think that errors are always undesirable, and _usually_ that's true - but there are some cases where they can be worthwhile and desirable.

# To understand how the system fails

I am a huge proponent of [Chaos Engineering](https://en.wikipedia.org/wiki/Chaos_engineering) - "_the discipline of experimenting on a software system in production in order to build confidence in the system's capability to withstand turbulent and unexpected conditions_". An illustrative example: a runtime configuration that artifically injects latency in calls to a dependency service, simulating a situation where the dependency is having issues. By carrying out an experiment where this configuration is gradually activated/increased, you can see how your service will respond to perceived increased latency. Do the automatic mitigation responses (whatever they might be - scaling up, backing off, switching to offline processing, using different code paths for a degraded experience, etc.) kick in? If not, you probably need to end the experiment, find out why they didn't work, and fix that before you encounter an issue like this in production (where you can't just turn off the issue!).

This is a bit of a cheat, since including hooks for Chaos Engineering is not technically an error - the system _does_ perform as required, where one of the requirements is "_when I pull this runtime lever, \<bad stuff\> happens_" - but I included it because:

* It requires a considerable change-of-paradigm to recognize that having "_built-in failure injection points_" is a _good_ thing.
* I will never pass up an opportunity to talk about Chaos Engineering :)

# As a newbie/ramp-up task

Software is ever-changing, as are software teams. You are going to have to change the system at some point[^4], and someone new is going to have to learn how to change the system if you plan to grow your team and/or replace developers who have left. That being the case - when an experienced developer sees a minor error that doesn't significantly impact the performance of the system, but is still _wrong_, it might be beneficial for them to fight the urge to bugfix and instead to record it in a list of "_suitable ramp-up tasks for new developers_". The newbie can take on this simple task and, in so-doing, learn about how to develop the system.

## To increase engagement

The description above applies to systems that are owned by a dedicated team in a professional setting, where a new hire can be directed to work on a suitable ramp-up task. In an Open-Source setting, however, the motivation structure is a little different. There, straightforward and visible tasks might be considered as "_bait_" - something that tempts an observer into making a contribution, after which they might be tempted to contribute further work to the project (in fact, I suspect that I recently fell for [one of them](https://github.com/pivpn/pivpn/pull/1427) myself...)

Some GitHub repos even have [specifically-tagged issues](https://github.com/MunGell/awesome-for-beginners) for first-time contributors!

## To encourage customization

When distributing a tool or framework that accepts parameterization and customization, it's reasonable to provide sensible defaults for parameters. However, a canny author might intentionally set a default parameter to an undesirable value - not a disastrous or dangerous one, but simply an aesthetically-unpleasing one. The hope there would be that a user would see the result, take steps to change it, and thereby be prompted to discover the customization options that exist (and, hopefully, make further use of them).

In fact, this was the concept that prompted this post in the first place! The default `16rem` `padding-bottom` at the bottom of `main.pb7` in Ananke is, to my eyes, _far_ too large. I started thinking about why an otherwise-well-designed theme might include such a choice (because, of course, my subjective design preferences are objectively and irrefutably correct :P ), and wondered whether this might be the case.

(Astute readers will note that I have written several hundred words about making errors before than finding a way to fix the originally-noted issue. Draw your own conclusions.)

# To track down leaks or identify imitators

(EDIT: this section added on 2021-12-26)

A [Canary Trap](https://en.wikipedia.org/wiki/Canary_trap) involves embedding unique identifiers into information given to various parties. If that information is then shared elsewhere, the identifier can be used to determine [who leaked it](https://www.youtube.com/watch?v=JMxkoYAG9r0). For instance, different versions of a screenplay might contain unique typos.

Similarly, when compiling authoritative reference information (such as a dictionary or a map), authors might include [fictious entries](https://en.wikipedia.org/wiki/Fictitious_entry) that do not reflect actual reality. A plagiarist can be identified by the fact that they will copy this fictitious entry.

# As an indicator or prompt to do something important

Famously, Van Halen's concert rider included the request that their dressing room feature a bowl of M&M's with all the brown ones removed. This was derided as posturing rockstars demanding pandering, and could be considered an "error" in the rider that it required unreasonable effort that was not justified by outcome (my effort to remove all the brown M&Ms is going to outweigh your pleasure at being so-coddled) - but there was actually a [good reason for it](https://www.insider.com/van-halen-brown-m-ms-contract-2016-9). The band had one of largest and most complex lighting rigs of the time, which required serious attention to install safely. The bowl of M&M's was a quick indicator - if there are brown M&M's in the bowl, then someone hasn't read the contract carefully, and so they couldn't trust the rest of the setup either.

Similarly - say you have created a system that should be run in an environment that has been initialized in some way. If the system can detect that state, then all well and good - you can have the system do a check at startup, and error out if the environment isn't correctly initialized. But if the system _can't_ detect that state, you can have the system behave in a way that is undesirable in a way that is noticable, but still "good enough". The [Flask server](https://flask.palletsprojects.com/en/2.0.x/), for instance, prints `WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead` whenever it is run. This isn't actively _desirable_ behaviour (from the perspective of simply "_being a server_", printing out this message does no good), so arguably falls under the category of error - but that undesired output still has the desired effect of prompting a developer to avoid using this server in production where they might otherwise have done so.

Still, you can't rely on this technique too much. From personal experience (but with some details obfuscated or changed) - there was a script we used at work that collated information from various sources into a single report. The oncall would be responsible for running it before the weekly meeting where we'd review the report, as well as making sure that they'd filled out the page that was one of the sources for the script, otherwise that part of the report would be empty. To make sure that they remembered to do so, the script would error out immediately unless it was called with a `--I-promise-I-have-remembered-to-update-the-source-page` flag.

I returned to work after taking some PTO, and heard that this script had been moved to an automated job. Interesting, I thought - how had they adapted the oncall-prompt to this new system? Was there an email sent shortly before the "main" script fired, and the main script would error out if the "last edited" date of the Wiki page was too long in the past or if some "update finished" marker-text wasn't present?

I checked the crontab - and, lo and behold, the script was being called with `./generate-report.sh --I-promise-I-have-remembered-to-update-the-source-page`. Sigh.

---

On an unrelated note, I added a [script](https://github.com/scubbo/blogContent/commit/4e2da707fc4a19196826deccb8b46dee4c4a8f9d) to this repo that simplifies the creation (and opening-for-editing) of new posts. Now if I could only automate _writing_ them... ;)

[^1]: I'm using "error" here to mean "_implementation of a system such that the system will not behave according to expectations or requirements_". The terminology in this space is a little confusing - I think that, according to guides like [this](https://stackoverflow.com/questions/6323049/understanding-what-fault-error-and-failure-mean/47963772), I am actually describing "_Failures_", but that is the opposite of the natural English meaning to me - "_You have erred, which caused the system to fail - thus, you made an error, which caused a failure_". [^2]

[^2]: This is my first time discovering that [Hugo supports footnotes](https://www.markdownguide.org/extended-syntax/#footnotes), and I am delighted! That said, if anyone can explain to me how to put definitional content like footnote 1 in the `<aside>` column in Ananke _alongside_ the content, rather than at the bottom, I'd be much-obliged![^3]

[^3]: It is so unspeakably on-brand for me to triple-nest footnotes the first time I use them.

[^4]: I have my criticisms of [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html), to say nothing of my criticisms of [its author](https://www.getrevue.co/profile/tech-bullshit/issues/tech-bullshit-explained-uncle-bob-830918) - but one excellent takeaway is that it's preferable to have a system that is incorrectly implemented, but easy to change, than it is to have a system that is correctly implemented, but hard to change. This is true for two reasons; first, because the claim that the system is correctly implemented might be false (for any sufficiently complex system, asserting correctness in all states is impractical); second, because what is correct and desired today may not be desired tomorrow, in the face of changing business requirements.