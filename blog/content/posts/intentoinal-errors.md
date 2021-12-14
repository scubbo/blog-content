---
title: "Intentoinal Errors"
date: 2021-12-13T21:36:09-08:00
draft: true
---

There's an [apocryphal story](https://rachelbythebay.com/w/2013/06/05/duck/) from the development of a game called Battle Chess. A Product Manager was well-known to _always_ have to make a comment or propose a change on anything, [no matter how minor](https://en.wikipedia.org/wiki/Law_of_triviality) - so, an engineer intentionally added an incongruous companion duck in a piece's animation. The PM could say "_looks good - but lose the duck_", and feel that they'd had a meaningful impact, when in fact the end result after removing the "sacrificial duck" was exactly as the engineer had originally intended.

There's a whole other blog post in there about the psychology of cooperative labour and the importance of feeling that you are contributing (which is increasingly hard as your role becomes more separated from the "coal face"), or about learning to work around observed behaviours of those with control in an organization (though, as a [Hacker News comment](https://news.ycombinator.com/item?id=9139639) points out - by indulging this kind of behaviour, you are probably incurring "Organizational Tech Debt" and not doing your manager any favours as their bad behaviour calcifies), but today I actually want to talk the different flavours of intentional error[^1]. You might think that errors are always undesirable, and _usually_ that's true - but there are some cases where they can be worthwhile and desirable.

# To understand how the system fails

I am a huge proponent of [Chaos Engineering](https://en.wikipedia.org/wiki/Chaos_engineering) - "_the discipline of experimenting on a software system in production in order to build confidence in the system's capability to withstand turbulent and unexpected conditions_". An illustrative example: a runtime configuration that artifically injects latency in calls to a dependency service, simulating a situation where the dependency is having issues. By carrying out an experiment where this configuration is gradually activated/increased, you can see how your service will respond perceived increased latency. Do the automatic mitigation responses (whatever they might be - scaling up, backing off, switching to offline processing, using different code paths for a degraded experience, etc.) kick in? If not, you probably need to end the experiment, find out why they didn't work, and fix that before you encounter an issue like this in production (where you can't just turn off the issue!).

This is a bit of a cheat, since including hooks for Chaos Engineering is not technically an error - the system _does_ perform as required, where one of the requirements is "_when I pull this runtime lever, \<bad stuff\> happens_" - but I included it because:

* It requires a considerable change-of-paradigm to recognize that having "_built-in failure injection points_" is a _good_ thing.
* I will never pass up an opportunity to talk about Chaos Engineering :)

# As a newbie/ramp-up task

Both software, and software teams, are rarely static. You are going to have to change the system at some point[^4], and someone new is going to have to learn how to change the system if you plan to grow your team and/or replace developers who have left. That being the case - when an experienced developer sees a minor error that doesn't significantly impact the performance of the system, but is still _wrong_, it might be beneficial for them to fight the urge to bugfix and instead to record it in a list of "_suitable ramp-up tasks for new developers_".

## To increase engagement

The description above applies to systems that are owned by a dedicated team in a professional setting, where a new hire can be directed to work on a suitable ramp-up task. In an Open-Source setting, however, the motivation structure is a little different. There, straightforward and visible tasks might be considered as "_bait_" - something that tempts an observer into making a contribution, after which they might be tempted to contribute further work to the project (in fact, I suspect that I recently fell for [one of them](https://github.com/pivpn/pivpn/pull/1427) myself...)

Some GitHub repos even have [specifically-tagged issues](https://github.com/MunGell/awesome-for-beginners) for first-time contributors!

## To encourage customization

When distributing a tool or framework that accepts parameterization and customization, it's reasonable to provide sensible defaults for parameters. However, a canny author might intentionally set a default parameter to an undesirable value - not a disastrous or dangerous one, but simply an aesthetically-unpleasing one. The hope there would be that a user would see the result, take steps to change it, and thereby be prompted to discover the customization options that exist (and, hopefully, make further use of them).

In fact, this was the concept that prompted this post in the first place! The default `16rem` `padding-bottom` at the bottom of `main.pb7` in Ananke is, to my eyes, _far_ too large. I started thinking about why an otherwise-well-designed theme might include such a choice (because, of course, my subjective design preferences are objectively and irrefutably correct :P ), and wondered whether this might be the case.

(Astute readers will note that I have written several hundred words about making errors, rather than finding a way to fix the originally-noted issue. Draw your own conclusions.)

TK - reference also the [Van Halen Test](https://www.insider.com/van-halen-brown-m-ms-contract-2016-9)
TK - copy detection
TK - story from work about `--yes-i-have-updated-the-foo-page`, or Flask server's `WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead`

---

On an unrelated note, I added a [script](https://github.com/scubbo/blogContent/commit/4e2da707fc4a19196826deccb8b46dee4c4a8f9d) to this repo that simplifies the creation (and opening-for-editing) of new posts. Now if I could only automate _writing_ them... ;)

[^1]: I'm using "error" here to mean "implementation of a system such that the system will not behave according to expectations or requirements". The terminology in this space is a little confusing - I think that, according to guides like [this](https://stackoverflow.com/questions/6323049/understanding-what-fault-error-and-failure-mean/47963772), I am actually describing "_Failures_", but that is the opposite of the natural English meaning to me - "_You have erred, which caused the system to fail - thus, you made an error, which caused a failure_". [^2]

[^2]: This is my first time discovering that [Hugo supports footnotes](https://www.markdownguide.org/extended-syntax/#footnotes), and I am delighted! That said, if anyone can figure out how to put definitional content like this in the `<aside>` column in Ananke _alongside_ the content, rather than at the bottom, I'd be much-obliged![^3]

[^3]: It is so unspeakably on-brand for me to triple-nest footnotes the first time I use them.

[^4]: I have my criticisms of [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html), to say nothing of my criticisms of [its author](https://www.getrevue.co/profile/tech-bullshit/issues/tech-bullshit-explained-uncle-bob-830918) - but one excellent takeaway from it is preferable to have a system that is incorrectly implemented, but easy to change, than it is to have a system that is correctly implemented, but hard to change. This is true for two reasons; first, because the claim that the system is correctly implemented might be false (for any sufficiently complex system, asserting correctness in all states is impractical); second, because what is correct and desired today may not be desired tomorrow, in the face of changing business requirements.