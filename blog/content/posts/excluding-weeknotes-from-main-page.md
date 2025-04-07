---
title: "Excluding Weeknotes From Main Page"
date: 2025-04-06T21:18:49-07:00
tags:
  - Meta
  - Tech-Snippets

---
I just went to write up a new [weeknotes]({{< ref "/tags/weeknotes" >}}) post, and noticed that that would have meant that all three previewed posts on my main page would have been weeknotes. That simply will not do! So into the depths of Hugo layouts I ventured once more.
<!--more-->
The relevant part of the original layout looks like[^line-numbers] this:

```
...
{{ $section := where $.Site.RegularPages "Section" "in" $section_name }}
{{ $section_count := len $section }}
{{ if ge $section_count 1 }}
  <div class="pa3 pa4-ns w-100 w-70-ns center">
    {{/* Use $section_name to get the section title. Use "with" to only show it if it exists */}}
    {{ with $.Site.GetPage "section" $section_name }}
        <h1 class="flex-none">
          {{ $.Param "recent_copy" | default (i18n "recentTitle" .) }}
        </h1>
      {{ end }}

    {{ $n_posts := $.Param "recent_posts_number" | default 3 }}

    <section class="w-100 mw8">
      {{/* Range through the first $n_posts items of the section */}}
      {{ range (first $n_posts $section) }}
        <div class="relative w-100 mb4">
          {{ .Render "summary-with-image" }}
        </div>
      {{ end }}
    </section>
...
```

Although the [where function](https://gohugo.io/functions/collections/where) does have a pretty good selection of operators, there's no `not` or `not intersection` - so, although it's possible to [filter to all members which have a particular slice-term contained in some other slice](https://gohugo.io/functions/collections/where/#intersection-comparison), it's not immediately possible to find all members that _don't_ have a given value in a slice-term. Thankfully, [later in the same docs](https://gohugo.io/functions/collections/where/#inequality-test) there's a link to [`collections/complement`](https://gohugo.io/functions/collections/complement/), which does exactly what I want. The final result was:

```
...
{{ $section_original := where $.Site.RegularPages "Section" "in" $section_name }}
{{ $weeknotes := where $section_original "Params.tags" "intersect" (slice "Weeknotes") }}
{{ $section := complement $weeknotes $section_original }}
...
```

Since I don't want those weeknotes to be undiscoverable, though, I also added a dedicated section for them on the homepage. Pretty happy with how that turned out!

[^line-numbers]: Hmm, note to self for a TODO - automatically adding line-numbers into monospace blocks would be nice!
