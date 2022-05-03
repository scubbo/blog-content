---
title: "Self Hosting Blog"
date: 2022-05-02T19:01:33-07:00
tags:
  - meta
  - homelab
---
Despite this blog being [initially set up to primarily talk about self-hosting]({{< ref "/posts/my-first-post." >}}), I'd actually been hosting it on AWS until very recently. This was due to caution - I know just enough about security to know that I know next-to-nothing about security, and so I didn't want to expose any ports on my _own_ network to the Internet. Instead, I set up [an AWS CodePipeline](https://github.com/scubbo/blogCDN) to build the blog and deploy to S3 anytime I pushed a new change. Admittedly, this was a pretty cool project in itself that taught me a lot more about CDK and some AWS services; but it didn't feel like true self-hosting, even though I wasn't using anything like Medium or WordPress.
<!--more-->
Thanks to [this great blog post](https://eevans.co/blog/garage/), I found an alternative that allowed me to feel the nerd-pride of self-hosting while retaining security. [Cloudflare](https://www.cloudflare.com/) offer a free service called "_Cloudflare Tunnel_" (formerly "_Cloudflare Argo_"). To quote that blog:

> This approach solves a lot of problems at once: there’s no need to open up any inbound firewall ports (hooray!); I don’t need to set up dynamic DNS records for my home IP address (which would, among other things, have some bad privacy implications); and I get Cloudflare’s DDoS protection and CDN features (which I would have wanted anyways for the blog). And crazily enough, it’s all free!

My setup's a little different than that author's (for one thing, I'm not running k8s...yet...), but the approach still works just fine. I built:
* a [script that runs as part of my primary homelab Pi setup](https://github.com/scubbo/pi-tools/blob/main/scripts-on-pi/3_cloudflare_tunnel.sh) which creates the tunnel (from `blog.scubbo.org` to a port on the local machine)
* a [script that's part of the blog content repo](https://github.com/scubbo/blogContent/blob/main/deployBlog.sh) which will pick up any new content, rebuild, and host on that same port.

I do admire the elegance of my previous setup (and of the setup I'm copying) whereby a push to the repo will trigger the build-and-republish - but, since I haven't taken the plunge to self-host [Gitea](https://gitea.io/en-us/) yet[^1], that will have to wait. I suppose I _could_ set up a local server (to trigger rebuild) which is called by a GitHub action after pushing, but that seems like throwaway work for nothing.

I also don't have quite the same level of paranoia as the author about network rules. That said, I did just install an OPNSense router (to replace the ISP-provided router that kept dropping my Raspberries Pi after a few days of uptime), so learning more about VLANs and Route Tables could well be in my future, too.

[^1]: and probably never will until I have [Backblaze](https://www.backblaze.com/) or some other reliable backup system setup - I trust GitHub's durability more than my own, and losing my code would be game over!
