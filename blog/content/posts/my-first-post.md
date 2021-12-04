---
title: "My First Post"
date: 2021-12-04T11:21:26-08:00
---
In true navel-gazey meta style, the first post on this blog is a description of how I set up the blog.
<!--more-->
# What's this all about?

I spend a _lot_ of time tinkering with technical projects, but I tend to struggle to complete or "ship" them. My hope is that making a commitment to writing about what I'm working on will prompt me to remain more focused and to finish a project rather than being distracted by the next shiny idea.

At the same time, I'm probably learning a lot of information during that tinkering that others (including "_myself, but in the future_") could benefit from. Sharing experience and information is the cornerstone of the open-source philosophy of cooperation, and I hope that others can learn from and build on my work.

Finally, I'm firmly of the opinion that clear, communicative, and compelling writing is an important skill for anyone, especially a technical professional. This is an opportunity to practice and demonstrate that skill.

# How this works

If you prefer to understand a system by reading the code, and/or if you're already familiar with the concept of a self-mutating pipeline, you can go read the [infrastructure-definition package](https://github.com/scubbo/blogCDN/tree/main) or the [blog content package](https://github.com/scubbo/blogContent)

## What's a self-mutating pipeline?

This blog is deployed via a self-mutating pipeline. This is a system for responding to changes in code packages, by updating the corresponding technical applications. These code packages can define the logic that runs in the application (traditional code), and/or they can define the infrastructure _itself_ that the application runs on ("Infrastructure As Code", or IaC). When a change is pushed to the repository that stores the code packages, the latest state of the code is retrieved and built (converted from human-readable source code into machine-readable instructions), and the build output is sequentially deployed to various stages. The first stage is the self-mutation stage - the infrastructure package defines the pipeline _itself_, so if there are any changes to the pipeline's definition (for instance, adding another stage, or changing the build definition), they get applied here.

Later stages are for deploying the actual application itself. Each stage represents a logically-isolated instance of the application, and a pipeline will typically run a series of tests after making a deployment to ensure that the deployment worked before letting a change flow on to the next stage. In a full-scale globalized high-availability application, there might be multiple pre-production stages for various isolated layers of testing, as well as per-region deployment stages to minimize blast radius if a deployment breaks. For my dinky little blog, there's just a single stage - though I might add another "private" stage where drafts are visible, so that I can see how they'll look live before publishing them. If I add custom logic to support interactive elements like page views (see below), these would be tested on a pre-prod stage before deployment.

During the deployment, the infrastructure is changed to match the infrastructure specification that resulted from the build process. This includes updating any references to logic code to the latest versions.

## Why would you do this?

There are two ways to answer that question:
* The value of self-mutating pipelines and IaC _themselves_ are that they allow developers to apply the Best Practices of traditional logic-code development (version control, review, rollback, testability, reproducibility, composability) to the management of Infrastructure
* The value of using such heavyweight tooling for my own own personal blog, is...mostly just as a learning exercise and a challenge :) I could have put five posts up on Medium or Substack in the time it took me to implement this solution, but I've already learned a _lot_ along the way, to say nothing of the satisfaction of building something myself.

# Choices

## Choice of Hosting

Ironically, given that I initially intended to start this blog to discuss discoveries and projects in my attempt to Self Host All The Things, this blog is entirely remotely hosted. I did consider a setup where my blog server was locally hosted, but I don't yet trust my InfoSec knowledge enough to expose a publically-accessible service from my home network.

Because of my familiarity with AWS, CloudFront was an obvious choice for CDN; and, likewise, familiarity with GitHub made that the obvious choice for code/content hosting (I'm sure AWS CodeCommit would have worked too). It should be possible to have CloudFront fronting a locally-hosted server, and to _only_ grant CloudFront read access to that server, once I trust my InfoSec skills a little more.

## Choice of Platform

I ran through a few choices from [this list](https://github.com/awesome-selfhosted/awesome-selfhosted#blogging-platforms) when picking a blogging platform, excluding anything built in PHP because ain't nobody got time for that. Ghost looked promising, but when I ran it (as per [here](https://hub.docker.com/_/ghost/)), I consistently got an error (`InternalServerError: Knex: Timeout acquiring a connection. The pool is probably full. Are you missing a .transacting(trx) call?`) when trying to hit the server. [Antville](https://antville.org/) also sounded promising, but it looks like the development team is German, and my German skills are rusty. Speaking of Rust, [Plume](https://joinplu.me/) looked like it might have given me a chance to finally learn this hot "new" language - but it's "not actively maintained".

Eventually, I asked a friend for their experiences, heard about [Hugo](https://gohugo.io/), and got a working setup in seconds. Can't argue with that! Better yet, the output is staticaly-hostable (unlike some of the other platforms that require a platform-specific server to be running), meaning I can just dump files in an S3 bucket and shove CloudFront in front. Nice and easy.

I'd love to add view counts, or even comments (I'm sure anyone who's ever moderated an online community is already wincing at this naïvete), which will require some sort of active hosting. A project for another day!

# Closing thoughts

As we stare down the end of another pandemic year, I'm thinking about experimentation, habit-formation, and personal development. I _hate_ manipulative growth-hacking tactics like ending a video with a question or a prompt for hashtag-engagement - but, earnestly, I would _really love_ to get feedback on this project, via the social links in the header/footer or [email](mailto:scubbojj@gmail.com). In particular, Graphic Design Is Not My Passion, so any tips there are appreciated!