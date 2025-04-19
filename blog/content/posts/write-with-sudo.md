---
title: "Write With Sudo"
date: 2025-04-18T22:06:20-07:00
tags:
  - Tech-Snippets

---
A snippet that I find myself needing more often than I'd like to admit - when you've opened a file for editing in `vim`, but when you go to save you are reminded that it needs root permissions to do so.
<!--more-->
```
:w !sudo tee %
```

This translates to:
* `:w` - "write this file[^buffer] to..."
* `!` _ "...the stdin of the following command:"
* `tee %` - "the command `tee`, passed as argument \<the filename currently being edited\>"

[^buffer]: _Technically_ I think "this buffer" might be more accurate?

