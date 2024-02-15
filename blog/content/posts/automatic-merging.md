---
title: "Automatic Merging"
date: 2024-02-14T22:46:08-08:00
tags:
  - CI/CD
  - homelab
  - productivity
  - SDLC

---
When working on my personal projects, I typically just push straight to `main` - opening a PR just to approve it seems entirely pointless, as if I had been able to find any issues in my own work, I wouldn't wait to do it in a PR! However, this does mean that, if I forget to run any quality checkers (linters, tests, etc.), I won't find out about it until `on: push` GitHub Action runs, and even then I might not see the failure until several commits later.
<!--more-->
This problem _can_ be addressed with [pre-commit hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)[^spoiler], but I've never been a fan of them:
* As the documentation states, "_client-side hooks are not copied when you clone a repository_", meaning that any new collaborators (or even "_me after [blowing away the repo](https://xkcd.com/1597/)_") will silently miss out on them.
* On-commit seems like the wrong cadence to run quality checks - local commits should be fast and frequent checkpoints that you can return to (or juggle around) as needed, and adding friction to them makes development more precarious. Ideally, quality checks would run immediately prior to _pushing_, but the `pre-push` hook runs "_**after** the remote refs have been updated_", meaning[^do-i-understand-git] that even if they fail, the remote will still have been changed.

The other day I hit on a cool idea that would seem to address both problems - since GitHub allows PRs to be set to be automatically merged when all checks pass, perhaps I could set up a workflow whereby:
* I push commits to a `dev` branch
* An auto-merging PR is automatically opened _from_ that branch to `main`
  * If the checks pass, the PR is automatically merged
  * If it fails...well, I'd have to set up some non-email channel to notify myself about that, but that shouldn't be too hard

I did make [some progress on it](https://github.com/scubbo/edh-elo/tree/autoMergePR/.github/workflows), but ran into some issues:
* PRs cannot be created _in_ an AutoMerge state - they have to be set _into_ that state after creation. Although [this SO answer](https://stackoverflow.com/a/72259998/1040915) did describe how to do so, some quirk of GHA meant that that failed when executed _in_ a GHA context (claiming the PAT did not have permissions)
* All is well and good if the PR immediately passes - but if it fails and I make correcting commits onto `dev` (which update the PR), then when the PR passes and is squashed into a single commit to then be merged into `main`[^squash-and-merge], then `dev` and `main` will have diverged, and the next PR that's submitted from `dev` to `main` will appear to be contributing the preceding commits as well. Not ideal!

After a couple of hours of fiddling around, I returned to investigating `pre-commit` hooks, and found the [pre-commit](https://pre-commit.com/) _tool_, which provides a management interface for hooks. It unfortunately still requires manual installation (so a new contributor might not benefit from it - though, in fairness, that can be double-checked with CI checks), but the experience is smoother than writing hooks myself. I'll keep experimenting with it and see how I like it.


[^spoiler]: And - spoiler alert - after running into frustrations with my first approach, this was exactly what I ended up doing, using the [pre-commit](https://pre-commit.com/) tool.
[^do-i-understand-git]: I do admit I haven't actually tested this understanding. It does seem surprising, as it would make the `pre-push` hook basically useless. This also seems to contradict the documentation [here](https://github.com/git/git/blob/master/Documentation/RelNotes/1.8.2.txt) which states that "_"git push" will stop without doing anything if the new "pre-push" hook exists and exits with a failure._". So, maybe `pre-push` hooks _aren't_ useless? I've asked for more information on this [here](https://stackoverflow.com/questions/77998932/when-exactly-in-the-push-process-does-a-pre-push-hook-actually-run). But, the first counter-argument - and the convenience of the `pre-commit` _tool_ - have me still using `pre-commit` hooks, even if `pre-push` would have worked.
[^squash-and-merge]: I will die on the hill that "Squash And Merge" is the only sensible PR merge strategy. A Merge Commit means that you have non-linear history, and Rebase means that one _conceptual_ change is represented as however-many different commits were generated during development. There is no value whatsoever in preserving the frantic, scrabbling, experimental commits that were generated _during_ development - they are scaffolding that should be tidied away before presenting the finished product as a single commit![^irony]
[^irony]: Ironic, then, that in fact this tangled automation approach is one of the only cases where a Merge Commit would actually be...I can't believe I'm actually going to say this..._better_ 🤮
