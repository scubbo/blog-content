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
