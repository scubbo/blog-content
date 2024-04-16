---
title: "Edit Command Line in Zsh"
date: 2022-07-10T00:25:21-07:00

---

**EDIT 2024-04-16**: turns out that there's a [built-in](https://www.computerhope.com/unix/uhistory.htm), `fc`, which does basically the same thing, though it edits the command that was _just entered_ (which is typically what you want when you encounter an error or want to do "the next thing", anyway).

While reading through my dotfiles, I found some [configuration](https://github.com/scubbo/dotfiles/blob/690f907f9ae36e36fed9851eac3a4ff2c20d7905/zshrc-local-mactop#L144-L147)[^1] that didn't seem to be working - it claimed that `<ESC>,v` would allow editing of the current line in vim, but that didn't seem to work. I guess I'd copied that from some other configuration and lost patience with trying to get it working, or that it relied on some other configuration option which had been broken[^2]. I dug in to find out more. ([This article](https://thevaluable.dev/zsh-line-editor-configuration-mouseless/) was invaluable!)
<!--more-->
## Intention

First, let's understand what that snippet is _trying_ to do. The ZLE (Zsh Line Editor) is a tool[^3] that allows for:
* the definition of various commands (called "widgets") for editing text.
* the binding of those widgets (or built-in or imported ones) to keys within named "keymaps". Commands can switch between keymaps.

Three standard keymaps in ZLE are `emacs`, `vicmd`, and `viins`. In the `viins` (vi-insert) keymap, the `<ESC>` key is associated with a widget that switches to the `vicmd` keymap:

```
$ bindkey -M viins '^['
"^[" vi-cmd-mode
```

(The character string `'^['` represents the single keypress `<ESC>`)

The line `bindkey -M vicmd v edit-command-line` means "_Within the keymap `vicmd`, bind the widget `edit-command-line` to the key `v`_". The earlier commands (`autoload edit-command-line; zle -N edit-command-line`) deal with making that widget available to ZLE - I guess it's not available by default?

So, taken as a whole, this configuration should make the key-sequence `<ESC>,v` translate to "_enter `vicmd` mode, then execute `edit-command-line`_". But that didn't seem to be the case.

## Investigation and resolution

I quickly noticed that my default keymap was not `viins` but `emacs`:

```
$ bindkey -lL main
bindkey -A emacs main
```

Quick fix, right? Add a line `bindkey -v`[^4] to my dotfile, and done?

Well, sort-of. [This change](https://github.com/scubbo/dotfiles/blob/fd2eb3f6a4f69721ea073f042cecae69d3457616/zshrc-local-mactop#L155) _did_ allow the `edit-command-line` to fire as expected, allowing the current line to be edited in `vi`; but, after "writing" the command and returning to the command line, I was not able to delete any character of the written command. Initially I thought this was because I was still in `vicmd` mode (and created a workaround custom widget [here](https://github.com/scubbo/dotfiles/blob/00089de2b7a18bc658fe8155afd19a51f46ba524/zshrc-local-mactop#L164-L171)), but that turned out to be an incorrect assumption. After looking around a little more, I found [this SO answer](https://unix.stackexchange.com/a/290403/30828) which suggested changing the binding for `'^?'` (that is - `<BACKSPACE>`) from `vi-backward-delete-char` to `backward-delete-char`. I'm not sure _why_, though - backspaces still work fine on the terminal before entering `vicmd` mode, which lends further credence to my suspicion that the ZLE is not the _entirety_ of the terminal, but merely a tool within it.

I've been making a lot of use of some Emacs-mode shortcuts:
* `Ctrl-A` => beginning of line
* `Ctrl-E` => end of line
* `Ctrl-U` => clear everything

So I added these to my setup with the following commands:

```
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^U' kill-whole-line
```

[^1]: Still in Github until I fully migrate to my self-hosted [Gitea](https://gitea.scubbo.org/) instance. I'm cautious of a circular dependency here - Gitea would need to be up-and-available to source dotfiles, but dotfiles would be referenced as part of the setup process for hosts (including the one that runs the Gitea instance).
[^2]: An idea - regression testing for dotfiles? Don't tempt me...
[^3]: The [article](https://thevaluable.dev/zsh-line-editor-configuration-mouseless/) says that the ZLE _is_ the command prompt, which...seems unlikely to me? I would think that the ZLE is a part _of_ the command prompt, but not all of it? Although the article contains a lot of useful information and insight, it also has some rather loose and imprecise statements, so I'm not sure how much to trust this.
[^4]: `bindkey -v` is an alias for `bindkey -A viins main` - in ZLE, you don't set a keymap as active, instead you set a keymap as an alias for `main`, and I think that's beautiful.
