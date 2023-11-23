---
title: "Pre-Pipeline Verification, and the Push-And-Pray Problem"
date: 2023-11-23T16:26:06-08:00
tags:
  - CI/CD
  - SDLC

---
It's fairly uncontroversial that, for a good service-deployment pipeline, there should be:
* at least one pre-production stage
* automated tests running on that stage
* a promotion blocker if those tests fail

The purpose of this testing is clear: it asserts ("_verifies_") certain correctness properties of the service version being deployed, such that any version which lacks those properties - which "is incorrect" - should not be deployed to customers. This allows promotion to be automated, reducing human toil and allowing developers to focus their efforts on development of new features rather than on confirmation of the correctness of new deployments.
<!--more-->
There's plenty of interesting nuance in the design of in-pipeline testing stages, but in this post I want to talk about the testing you do _before_ a pipeline - and, particularly, why it's important to be able to run Deployed Tests before submitting code.

## Definition of Deployed Testing

Categories of test are a fuzzy taxonomy - different developers will inevitably have different ideas of what differentiates a Component Test from an Integration Test, or an Acceptance Test from a Smoke Test, for instance - so, in the interests of clarity, I'm here using (coining?) the term "Deployed Test" to denote a test which can _only_ be meaningfully carried out when the service is deployed to hardware and environment that resembles those on/in which it runs in production. These typically fall into two categories:
* Tests whose logic exercises the interaction of the service with other services - testing AuthN/AuthZ, network connectivity, API contracts, and so on.
* Test that rely on aspects of the deployed environment - service startup configuration, Dependency Injection, the provision of environment variables, nuances of the excecution environment (e.g. Lambda's Cold Start behaviour), and so on.

Note that these tests don't have to _solely, specifically, or intentionally_ test characteristics of a prod-like environment to be Deployed Tests! Any test which _relies_ on them is a Deployed Test, even if that reliance is indirect. For instance, all Customer Journey Tests - which interact with a service "as if" a customer would, and which make a sequence of "real" calls to confirm that the end result is as-expected - are Deployed Tests (assuming they interact with an external database), even though the test author is thinking on a higher logical level than confirming database connectivity. The category of Deployed Tests is probably best understood by its negation - any test which uses mocked downstreams, and/or which can be simply executed from an IDE on a developer's workstation without any deployment framework, is most likely not a Deployed Test.

Note also that, by virtue of requiring a "full" deployment, Deployed Tests typically involve invoking the service via its externally-available API, rather than by directly invoking functions or methods as in Unit Tests.

## When do we do Deployed Testing? When _should_ we do it?

Deployed Testing most naturally occurs in the CD pipeline for the service. If you were to list the desired properties of a pipeline, right at the top would be "_It builds the application and deploys it to production_", but right below that would be "_...but before doing so, it deploys to a testing stage and runs tests to make sure the deployment to production will be safe_".

However! All too often I see this being the _only_ way that teams are able to run Deployed Tests - that they are literally unable to:
* create a deployment of the application whose artifact was built from the state of code currently on their local development machine
* run a Deployed Test suite against that deployment, where the logic of the tests again is determined by the state of code on their machine

The thinking seems to be that Deployed Tests will be executed in the pipeline _anyway_, so there's no point in running them beforehand - any "bad changes" will get caught and rolled back, so production will be protected. And this is true! But, by leaving the detection of issues until the last minute - when the change is _in_ the (single-threaded) pipeline and when any test failures will block other changes coming down the pipe; when other developers may have started developing against the changes already merged - the disruption of a failure is significantly higher. For low-confidence changes which relate to properties that are only testable in a Deployed Environment, developers have to "Push And Pray" - "_I **think** that this change is correct, but I have no way of verifying it, so I need to push it into the pipeline before I can get any feedback_". This cycle - push, observe failed test results, make local change, push again - might repeat multiple times before they get to working code, during which time the whole pipeline is unusable. They are effectively making the whole pipeline their personal development environment, blocking anyone else from deploying any changes or even making any code changes which depend on their (unstable) merged code.

It's a small amount of extra effort, but it's _entirely_ worthwhile to set up the ability described in the preceding bullet points, whereby developers can run locally-defined tests against a locally-defined service[^running-locally] before even proposing the change for merging to `main`. Note that this testing is worthwhile in both directions - not only can the dev run existing tests against a new AppCode change to confirm that it's correct, but they can also run a new version of the **Test**Code against existing AppCode to ensure that it operates as-expected!

## Ephemeral Environments are great, but are not enough

A closely-related topic is "_building and deploying the code associated with a Pull Request, running tests against it (and reporting on them in the Pull Request), and providing a URL where stakeholders can experimentally interact with the service (or, more commonly, website)_" (I don't know of a general term for this, but it's called "Ephemeral Environments" at my current workplace, hence the section title). This is a great practice! Anything you can do to give high-quality testing _early_ in the SDLC - critically, _before_ merging into `main` (after which the impact of a rollback or correction is much higher) - is valuable, particularly if it involves getting explicit signoff from a stakeholder that "_yep, that was what I expected from this change_".

However, there should be no need to involve a remote repository system (GitHub etc.) in the process of creating and testing a personal deployment. It _works_, but it's an extra step of unnecessary indirection:
* For any non-Cloud-based system, running an instance of the application from code you have built locally should be trivial - if it's not just `docker build ... && docker run ...`, there should be a very small number of scriptable steps.
* Even for apps that deploy to AWS, GCP, or another Cloud Provider, it should be possible to locally-build AppCode updates, and push the Docker image (or other artifact) to your personal testing deployment without getting GitHub/CodeCommit/CodePipeline involved.
* Testing of infrastructure changes are a little trickier, but depending on your IaC configuration _could_ still be possible - though at that point the creation of a deployment pipeline _for_ a personal testing environment is probably worthwhile.

Don't get me wrong, PR-related Ephemeral Environments are excellent for what they are, and I heartily recommend them - but if you don't know how to build and deploy your application _from your laptop_ without getting GitHub involved, you probably don't know[^knowledge-is-distributed] it well enough to properly operate it at all. Or, you may be [over-applying GitOps](https://fosstodon.org/@scubbo/111112129591386185) under the mistaken assumption that _nothing_ about _any_ system, _anywhere_, should _ever_ be changed triggered by _anything_ except by a change to a Git repo. That's not even true for production systems[^not-everything-is-gitops], so it's _certainly_ not true for development systems which have made the trade-off of flexibility and agility at the cost of stability. By all means insist, on a rigorous, centralized, standardized, high-confidence, reproducible, audit-logged process (i.e. a GitOps-y one) for everything _after_ "merge to `main`" (and _especially_ regarding "deploy to `prod`) - but, for everything before that point in the SDLC, prefer agility and fast-feedback with as few moving parts as possible.

[^running-locally]: ideally, but not necessarily, _running_ locally as well - though if there are aspects of the deployment environment that mean this is impractical (like depending on Cloud resources, large scale, or particular architecture), this isn't necessary
[^knowledge-is-distributed]: where the definition of "know" is a little fuzzier than just "_have the knowledge immediately to-hand in your mind_". If that "knowledge" consists of "_I know the script I need to run_", then that's good enough for me - it can live in your "_exobrain_", the collection of cognition- and memory-enhancing/supporting tools and structures that you use to augment your natural human brain.
[^not-everything-is-gitops]: when a customer changes their settings in the Web UI, is that change stored into a Git Repo before being reflected? No, it just gets written to a database? OK, so you acknowledge that _some_ properties of the system can have authoritative sources that are not Git repos - now we're just quibbling about where the appropriate dividing line is drawn. Personally I have long believed that "_which image/version is deployed to which stage of a pipeline?_" is properly viewed as an emergent runtime property of the-pipeline-viewed-as-a-software-system-itself, rather than a statically-(Git-)defined property of the application - it is State rather than Structure - but to fully explore that deserves its own post.
