---
title: "Short Thoughts 2022-03-05"
date: 2023-03-05T19:49:27-08:00
tags:
  - programming-challenges
  - rust
  - short-thoughts

---
It's a warm-ish Sunday evening in the East Bay. How are you?
<!--more-->
Trying to keep up the routine of writing at least one of [these]({{< ref "/posts/consistency-in-2023" >}}) a week. I'd like to make it more like 3-4 a week, but, eh, what are you going to do? I'm being especially kind to myself because this week's been pretty awful - on Monday morning I got an alert from a moisture sensor in the basement (which I'd honestly forgotten was even there as it hadn't alerted in the 2 years we've been here), and went downstairs to find the basement under nearly 2 feet of water. Cue some panicked calls to my most handy friends - thankfully they had a portable sump pump they could lend me, though leaving it running until 03:00 only succeeded in draining a few inches. I called an emergency plumber the following day who was able to drain the whole thing and diagnose the most likely cause - that the mold remediation folks who'd done some work the previous week had overloaded the electricity circuit in the basement, tripping the breaker and deactivating the sump pump which would otherwise have drained the water with no problem. Funtimes. On the bright side, the mold company do seem pretty amenable to paying appropriate damages, and the musty smell has already decreased, so...we'll see. The joys of homeownership! (I am aware this is an extremely first-world problem).

## I'm feeling rusty

I've been working through the [Rust track](https://exercism.org/tracks/rust) on exercism as part of their `#12in23` program, and boy it's a mindfuck. I really enjoyed [Seven Languages In Seven Weeks](https://amzn.to/3ZD7z1G) (Amazon Associates Link) for the way it portrayed different programming languages not as being differently capable (if you squint, pretty-much-any programming language can address pretty-much-any problem - no matter your opinion on [whether HTML is a programming language](https://briefs.video/videos/is-html-a-programming-language/)[^is-html-a-programming-language]), but rather as promoting different programming paradigms. Programmers talk about "_idiomatic_" code to mean code which not only solves the problem, but does so in _the way that the language wants you to solve it_. This is a hard concept to analogize, since I'm not aware of an equivalent discipline where there are plenty of equally-suitable tools for any given job but wherein the tools lend themselves to different approaches. Maybe you have a good example?

So anyway. Rust. It has been real rough on me. This is mostly because I learned on Java and Python, and so never had to deal with memory management, so (what I perceive to be) Rust's core unique feature ("borrow-checking" - a novel approach to garbage management) is requiring me to learn a whole new thing to keep in the back of my head while expressing my ideas. When I'm being mature about it, it's refreshing and humbling to regain that experience of being a beginner, of having to figure out new concepts with the benefit of my existing experience. When I'm being less mature, it feels frustratingly like walking through long grass full of rakes - I know where I _want_ to go, but I keep being smacked round the face with an error telling me that I can't do it that way.

Which ties back neatly to the concept of programming languages just being "_a different choice of what practices to elevate_". Poor engineers would decry Rust as being a bad language because it doesn't let them do what they want. Good engineers recognize that there is value in a tool that doesn't let you shoot yourself in the foot.

...but seriously, though. They say the Rust community is disproportionately transgender, but I bet there must be a high proportion of masochism in there, too :P

[^is-html-a-programming-language]: my $0.02 - HTML is a programming language by every consistent definition _except_, ironically, "_what people think of when they think of a programming language_" (A General-purpose Programming Language) - and so, the statement "_HTML is a programming language_", while technically true, would be misleading to the average audience. This is one of those situations where technical accuracy is less important than an awareness of the context in which your words will be understood - something that engineers often struggle with, and that various bigots on the Internet wilfully dismiss.
