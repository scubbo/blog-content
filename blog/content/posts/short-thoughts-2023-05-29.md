---
title: "Short Thoughts 2023 05 29"
date: 2023-05-29T10:37:45-07:00
draft: true
tags:
  - short-thoughts

---
What's the saying - "_If you want to make God laugh, tell him your plans_"? My last Short Thoughts post - where I was "_trying to keep up the routing of writing at least one of [these]({{< ref "/posts/consistency-in-2023" >}}) a week_" - was [nearly three months ago]({{< ref "/posts/short-thoughts-2023-03-05" >}}). Ah well, no use in beating myself up over it!
<!--more-->

## The Rust is still there

As in that previous post, I'm still wrestling with Rust. I finished working through [The Rust Book](https://rust-book.cs.brown.edu/) a couple weeks back, which helped a _lot_ with clarification of the important concept I was missing. The _idea_ of borrow-checking now makes perfect sense to me, and the promised outcome (all the speed of non-GC'd languages with none of the unsafety) is tantalizing - but I'd be lying if I claimed not to be frustrated by how bloody difficult it makes trivial operations like concatenating two strings or retrieving a value from a HashMap. Inspired by [Julia Evans' post on the pitfalls of floating-point numbers](https://jvns.ca/blog/2023/01/13/examples-of-floating-point-problems/), I tried throwing together an implementation of arbitrary[^arbitrary] precision numbers [here](https://gitea.scubbo.org/scubbo/rust-real-numbers). Still very much a work-in-progress - so far I've only implemented Addition, Subtraction, and Equality, there's no explicit testing of the "faults" of floating-point numbers nor of the performance, and I've already noticed a couple of points where I could improve the design. That said - if you are a talented Rustacean, all advice is welcome!

Tangentially, I note that the [Rust community](https://www.jntrnr.com/why-i-left-rust/) is going through some controversy. This is disappointing, as until now it had always seemed like an intentionally-crafted, inclusive and positive community. Here's hoping this is (as one HN commenter said) "_a moment the Rust community can look back on as a time that they really lived their values \[by doing the right thing\]._".

## In other news

Work at my new place (LegalZoom) is still going well. The role is "SRE", but the tech-support situation is such that we're trying our hand at Security, DevOps, and Builder Tools as well. I'm getting to wear many hats, and really enjoying it! Finally getting around to reading [Domain-Driven Design](https://amzn.to/3qkeHUk) after a coworker's evangelism. 1/4 of the way in, honestly most of it seems like self-evident truisms, which I guess is indirectly an extremely high compliment to a book that came out 20 years ago - it's been so enthusiastically adopted that what was once revolutionary is now accepted wisdom. I'm hoping that deeper insights will arise as I keep on.

Speaking of my new role - man, I still really miss the Builder Tools at Amazon. [Pipelines](https://blog.scubbo.org/posts/ci-cd-cd-oh-my/) remains one of the smoothest and most productivity-multiplying tools I've ever used[^disagree]. A unified build system and established deployment mechanism were a godsend for developers working on new services - even more so for an SRE trying to build tools atop them! Don't get me wrong, it's exciting to be able to build them all from scratch - but every so often I do want something to Just Work 😊

I am warming up to the concept of release branches, though. At first, they seemed like nonsense - why would you cut a branch in order to release, why aren't you releasing "_the latest build that passes tests_" immediately, that's exactly what CD should be? Having seen the mess that can result from shared testing environments, no pre-pipeline testing, and general lack of accountability for deploying irresponsibly, I can see the value in _temporarily_ having a little more process around releasing _until_ we address all those things.

I still think, though, that any deployment mechanism that relies on a human _trying_ to replicate the code-state from environment N into environment N+1, rather than a machine reliably doing so automatically, is crazytown banana-pants, though.

Look at that, it's been nearly 45 minutes for this "short thought" which is meant to be only 15 minutes. Back to the Rust mines I go!

## But one last thing

I updated the formatting on the [tags page](https://blog.scubbo.org/tags/) so there are three boxes alongside each other, rather than one taking up all the horizontal space. Thanks to my buddy Jeff for the help there! (Link to his site to come once he's set up his home-server 👀)

[^arbitrary]: well - technically it only supports numbers up to `INT_MAX` and down to `2147483647` decimal places. I could probably go to smaller(/arbitrary) precision if I used a List of Maps for the decimal places rather than a single one...
[^disagree]: sorry Ziggy, I still disagree with literally every thing you said [here](https://twitter.com/ZiggyTheHamster/status/1577076232243380230) - Pipelines _does_ do the things you're saying it doesn't do, it just does reflects them in non-standard ways, but the results are the same. It's a double standard to claim that Pipelines "doesn't" do those things because it calls out to other systems (CodeBuild, CodeDeploy, etc.), while simultaneously claiming that (say) Jenkins, GitHub Actions, or Circle "do" them when in fact they are just orchestrators for other chunks of logic too.