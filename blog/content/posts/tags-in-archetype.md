---
title: "Tags in Archetype"
date: 2022-07-02T17:16:43-07:00
tags:
  - meta
---
I've been using tags - or [taxonomies](https://gohugo.io/content-management/taxonomies/), as Hugo more generally calls them - to organize posts in this blog for a while, but haven't imposed much structure on them. I tend to just apply whatever tags feel appropriate at the time I'm writing, which led to posts with [near](https://gitea.scubbo.org/scubbo/blogContent/src/commit/bcb50c6997d9179d899945c481d8588d63d22fa5/blog/content/posts/my-first-post.md?display=source#L5)-[duplicate](https://gitea.scubbo.org/scubbo/blogContent/src/commit/bcb50c6997d9179d899945c481d8588d63d22fa5/blog/content/posts/commenting-enabled.md?display=source#L5) tags[^0]. We can solve this problem with COMPUTERS[^1]!
<!--more-->
Hugo uses [archetypes](https://gohugo.io/content-management/archetypes/) as templates for the creation of new content - particularly, of new posts. Heretofore, my post archetype has just provided a single placeholder tag - [`FillInTagHere`](https://gitea.scubbo.org/scubbo/blogContent/src/branch/main/blog/archetypes/default.md?display=source#L6) - to remind me to enter tag(s). However, by adapting a [template](https://gohugo.io/templates/introduction/)[^2] to [list all elements in the `tags` taxonomy](https://gohugo.io/templates/taxonomy-templates/#example-list-all-site-tags), I was able to change the archetype so that any freshly-created post lists all extant tags, from which I can delete any irrelevant ones. I can't link directly _to_ that archetype from this post because, at the time of writing the post, the associated commit doesn't exist (though you can of course find it in the "page source" of this post, as described [here]({{< ref "/posts/page-source-link" >}})) - for reference, it looks like this:

```
---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true
tags:
{{ range .Site.Taxonomies.tags }}  - {{ .Page.Title }}
{{ end }}
---
This is the introduction
<!--more-->
And this is the rest of the content

```

Note that I had to put `  - {{ .Page.Title }}` on the _same_ line as the `{{range}}` statement, otherwise I would get an extra line-break after each tag element.

Honestly, I'm a little surprised that this works in the first place. I would have expected that fetching "_a list of all extant tags_" would require building the site, but I've confirmed that this template still works when no `public/` directory (the usual location of built output of a Hugo site) exists. Either the list of extant tags is stored as metadata somewhere (though a `grep -r` didn't find it), or Hugo quickly parses through all existing posts to gather a list of tags when creating a new post from an archetype[^3].

On the topic of tags, I have a couple of improvements I want to introduce:
* The [tags](https://blog.scubbo.org/tags/) page is pretty poorly-laid out, taking up a lot of space for the tag name and showing the preview of the blog posts under it. This means that, on my standard Macbook screen, you can just about see 3 posts'-worth of content (that is - a single tag) - not ideal! ~~It'd be great to restructure this so that the tag name is much smaller, and only the titles of posts under it are shown (maybe with an option to hover to see preview), allowing more content to be readable from a single screenful.~~ Done, as of 2023-05-17, thanks to my buddy Jeff the front-end wizard!
  * It looks like you can [attach metadata](https://gohugo.io/content-management/taxonomies/) to tags, too - that might be good to do (and to show as a subtitle for the tag) to clarify what a particular tag encompasses (no, `#meta` is _not_ related to The Company Formally Known As Facebook!)
  * I'd like to try messing with the ordering[^4] on that tags page, too. At a glance, it looks like it's sorting by "_most recent post within that tag_", which...I guess makes sense. My first thought was that ordering by "_number of posts in tag_" might make more sense (putting "larger" tags above smaller ones), but that might lead to discoverability problems if I write a bunch of posts under one tag and then it's harder to find later ones. Then again, later posts would presumably show up on the standard page anyway? Eh - that's Future-Jack's problem when he starts thinking about this problem (if, indeed, he ever does...)
* I haven't messed around with the RSS feed for my blog, yet, but it seems like subscribers might want to subscribe to only certain tags, or to exclude certain tags. I imagine it would be pretty easy to create feeds at build-time for any pre-defined criteria ([this article](https://benjamincongdon.me/blog/2020/01/14/Tips-for-Customizing-Hugo-RSS-Feeds/) describes how), but probably more difficult (probably impossible? Since the feed is created _at_ build-time) to create arbitrary filter-condition feeds at render-time. I guess a Good Enough solution would be to generate feeds for each tag, and allow readers to subscribe to any combination of them that they like.
* It seems like the "related" sidebar only ever shows previous content - [this post](https://blog.scubbo.org/posts/cheating-at-word-games-part-3/) shows the two preceding posts under the tag, but [this one](https://blog.scubbo.org/posts/cheating-at-word-games/) doesn't show any. That's both puzzling (the full list of "_posts that exist under a given tag_" must be available at _some_ point in the build process, and it's not like running a second iteration over all blog posts will massively affect runtime efficiency of the process) and counter-intuitive (a reader who is linked to the first blog post in a series would want to be able to easily find a link to the next one without clicking out to the tag page or the author explicitly adding the link in the body). This _should_ be pretty simple to solve by using a [Taxonomy Template](https://gohugo.io/templates/taxonomy-templates/#list-content-with-the-same-taxonomy-term), but I'd be more curious to find out why this wasn't implemented the _complete_ way to begin with.

---

**EDIT:** well, there's an easy-ish solution to including newer content in the Related Items sidebar. Turns out it was simple as changing a single value - `related.includeNewer` - in Hugo's configuration, as described [here](https://gohugo.io/content-management/related/).  Unfortunately, "_If you add a_ `related` _config section, you need to add a complete configuration. It is not possible to just set, say,_ `includeNewer` _and use the rest from the Hugo defaults._", so I had to copy the entire default configuration and change a single value in it. The fact that that config option is specifically called out as the example suggests that this is a common non-default configuration - I am vindicated! The justification given in documentation for the default option is that including newer related content "_will mean that the output for older posts may change as new related content gets added_", which I _guess_ could be considered as unexpected behaviour if you expect a post to remain immutable once published.

However, the resultant Related Pages are (presumably) listed in order of "most-to-least-related" (with order undefined between pages that are equally-related) - or, at least, I can say that they're not listed in a consistent date order, because during testing, the related pages for the [2nd Wordle post]({{< ref "/posts/cheating-at-word-games-part-2" >}}) listed 1 then 3, but the related pages for the 3rd post listed 2 then 1. The sort-order for the Related Pages isn't a configurable option, so, in order to change this, I had to override [Ananke's default layout for sidebar content](https://github.com/theNewDynamic/gohugo-theme-ananke/blob/master/layouts/partials/menu-contextual.html) - I changed:

```
{{ $related := .Site.RegularPages.Related . | first 15 }}

{{ with $related }}
...rendering of each item of $related
```

to

```
{{ $related := .Site.RegularPages.Related . | first 15 }}
{{ $related_sorted := sort $related "Date" "desc"}}

{{ with $related_sorted }}
...rendering of each item of $related_sorted
...
```

So far as I can tell, it's not possible to pipe _into_ `sort`, you have to have it return to a new variable.


[^0]: These links are permalinks to a previous commit, because as part of the commit that introduces _this_ post, I unified those disparate tags to a single `#meta` tag.
[^1]: Disclaimer: computers will almost always introduce more problems than they solve. The only code that is guaranteed to lead not to lead to a net-increase of problems is [this](https://github.com/kelseyhightower/nocode).
[^2]: Confusingly, "Archetypes" do what you might naïvely expect "Templates" to do. Explicitly: Archetypes are ~~templates~~ prototypes from which new content are created, and Templates are ways to express code-like logic in a non-code context, or equivalently to provide an execution/extension point in non-code content that expresses "_execute some code, and insert the output here_". An example of a template is writing the following in a blog post (note that this is not legal template syntax!): "_If you're interested in learning more about this topic, check the following posts: `{{ getAllPostsWithTag "coolTopic" | .Title}}`_", to print the titles of all posts with tag `#coolTopic`.
[^3]: Which then raises the question - does it _always_ do this, or only when the archetype includes a template that requires it? File this under "_things I would be interested to know, but not interested **enough** to go find out for myself_"
[^4]: I _still_ instinctively use "_sequencing_" instead of "_ordering_" to describe "_establishing which elements precede which other elements_", even though the area of mathematics that deals with that is literally called [Order Theory](https://en.wikipedia.org/wiki/Order_theory). This habit arose from when I was working on two services in my previous job - one of which was responsible for selecting the order (sequence) for laying out the various means of acquisition of content, and the other which was responsible for submitting orders (attempts to purchase) for said content. I should try to break that habit, since "_order_" is the more-common term and is unambiguous except in that particular context.
