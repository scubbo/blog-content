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

<!--
Reminders of patterns you often forget:

Images:
![Alt-text](url "Caption")

Internal links:
[Link-text]({{< ref "/posts/name-of-post" >}})
-->