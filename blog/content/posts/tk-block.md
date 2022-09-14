---
title: "T​K Block"
date: 2022-08-23T21:46:40-07:00
draft: true
tags:
  - meta

---
I just added a process to my blog deployment pipeline to block the deployment of any blogs that contain the characters "T​K".
<!--more-->
## Why

"T​K" is a [printing and journalism reference](https://en.wikipedia.org/wiki/To_come_(publishing)) indicating that more content is "To Come" (the mismatching initialism is intentional, since very few English words contain the letters "T​K"[^1] - so a search for those characters is very unlikely to turn up a false positive).

One use of this is as a "placeholder", when you know _roughly_ what will go in a given place in a written work, but don't have the references or inclination to fill it out entirely. By just chucking "_T​K - a swordfight_" or "_T​K - analysis of European GDP_" in place, you can keep up your momentum by moving on to the parts that you _do_ feel ready to write right now[^2], and return to fill out the T​Ks once more-appealing options have been exhausted.

In the traditional publishing world, an Editor would be responsible for the final pass over the work to make sure all T​Ks have been caught before sending the content out to readers. In the thrilling world of the future where we have taught sand to think by blasting it with lightning, we can automate that process! Look at the changes to `.drone.yml` in the commit that introduced this blog post to see how.

## What about alerting?

Watch this space. I want the original commit to _only_ include the `.drone.yml` update and minimal blog post, to check it works. I'll post a follow-up with description of alerting (via Matrix) next.

If you're seeing this, then congratulations, you caught the blog post before it was meant to be published. But wait...this whole blog post was about how we'd now made that impossible, right? That's right!

## Wait, but...this blog contains the characters T​K?

I know! See if you can figure it out :)

[^1]: Alright, you know I couldn't resist checking:

```
$ cat /usr/share/dict/words | wc -l
  235886
$ cat /usr/share/dict/words | grep -i 't​k' | wc -l
      40
$ echo "100*40/235886" | bc -l
.01695734380166690689
```

So, _about 0.017%_ of common English words contain those characters. Some stand-outs include "_boat​keeper_", "_giant​kind_", and "_out​knave_".

[^2]: Though, see also George's thoughts on [Being Creative Uphill](https://www.georgelockett.com/shards/2022/7/28/being-creative-uphill) and [How To Write When You Can't](https://www.georgelockett.com/shards/2022/6/16/how-to-write-when-you-cant)
