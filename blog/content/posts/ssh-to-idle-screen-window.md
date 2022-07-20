---
title: "SSH to Idle Screen Window"
date: 2022-07-19T15:42:31-07:00
tags:
  - homelab

---
I've [written before]({{< ref "/posts/auto-screen" >}}) about setting up my ssh config so that I'll automatically join an existing screen session when ssh-ing to certain hosts, by setting `RemoteCommand screen -D -RR -p +`

However, this has a couple of issues:
* It will _always_ create a new window within the session, even if an idle window exists. More often than not, I find myself immediately killing the new window and switching to an existing one.
* It doesn't restrict the rejoin to a named session - in my current usage, I typically only have a single `screen` session open at once, but that could change!
<!--more-->
This didn't seem like too hard of a problem to solve - in pseudo-code, the algorithm should look like:

```
if !(named session exists):
  create and join named session
else
  for window in named session:
    if window is idle:
      join window
  else:
    create and join new window in named session
end if
```

Translated into shell code, that looks like:

```
Host host_nickname
  HostName hostname.avril
  RequestTTY force
  RemoteCommand sessionName=main; sessionSocket=$(ls /run/screen/S-pi | grep -E "^[[:digit:]]+\.$sessionName$"); if [ -z "$sessionSocket" ]; then screen -S "$sessionName"; else idleWindows=$(pgrep -P $(echo "$sessionSocket" | cut -d "." -f1) | xargs -I {} sh -c "echo -n '{}:'; pgrep -P {} | tr '\n' ':'; echo" | grep -E -v ':[[:digit:]]' | sed -n 's/:$//p'); if [ -z "$idleWindows" ]; then screen -D -RR -S "$sessionName" -p +; else screen -D -RR -S "$sessionName" -p $(tr '\0' '\n' </proc/$(echo $idleWindows | cut -d ' ' -f1)/environ | grep ^WINDOW= | cut -d '=' -f2);fi;fi
```

OK, that's....that's pretty gross. Let's break it down.

# Breakdown

## Variables

* `sessionName=main` - by declaring this right upfront, we make it easy to change the session name if desired.
* `sessionSocket=$(ls /run/screen/S-pi | grep -E "^[[:digit:]]+\.$sessionName$")` - the directory `/run/screen/S-<username>` contains sockets for each session started by `<username>`, with names of the form `<PID>.<sessionName>`. If we wanted, we could declare `sessionUser=pi` to make this configurable, but I think it's very unlikely I'll be interested in sessions started by other users.

## Create the session if it doesn't exist

`if [ -z "$sessionSocket" ]; then screen -S "$sessionName"` - that is, "_if the variable_ `$sessionSocket` _is empty (i.e. there was nothing in_ `/run/screen/S-pi/` _matching the sessionName - no such named session is running), then create a session with that name_"

That's the simple case. Moving into the `else` branch, where the session already exists and we need to join it, gets a bit more complicated.

## Find idle windows

`idleWindows=$(pgrep -P $(echo "$sessionSocket" | cut -d "." -f1) | xargs -I {} sh -c "echo -n '{}:'; pgrep -P {} | tr '\n' ':'; echo" | grep -E -v ':[[:digit:]]' | sed -n 's/:$//p')`[^1] [^2], broken down, is:

* `echo "$sessionSocket" | cut -d "." -f1` gets the processId of the session
* `pgrep -P <sessionPID>` finds all processes that are children of that session - that is, the processes of the windows.
  * This _works_, but I have the feeling that I'm misunderstanding or glossing over some complexity of `screen`'s operation (or, indeed, Unix process design) by relying on this fact. Note that [this SO answer](https://unix.stackexchange.com/a/556640/30828) recommends finding windows-in-a-screen by examining the output of `sudo w`, but it wasn't clear how to map from that output to the window numbers, nor how to tell whether an entry in `sudo w` corresponds with a `screen` window or not. In particular, `pts/<number>` entries seem to appear for regular `ssh` connections, for screen session parents, and for each window, so that's pretty unclear. If you understand how to parse `sudo w` to identify screens-and-windows, please do let me know!
* `pgrep -P <sessionPID> | xargs -I {} sh -c "echo -n '{}:'; pgrep -P {} | tr '\n' ':'; echo"` - for each window, list the child processIds of that window, colon-separated, on the same line. For instance, if there are windows with PID `001` and `002`, and window `001` has child process `003`, the output would look like:
```
001:003:
002:
```
* `pgrep -P <sessionPID> | <list children of window PIDs> | grep -E -v ':[[:digit:]]' | sed -n 's/:$//p` filters the preceding output to any lines that _don't_ (`-v`) contain "_a colon followed by a digit_" (that is - it filters to only the lines referring to a window with no children; an idle window), then `sed` removes the trailing colons from each line so we recover the processIds of the idle windows.
  * The grep here could have equivalently been `grep -E -v ':[^$]`, to search for "_any lines that don't contain a colon not at the end of the line_" => "_all lines whose only colon is at the end of the line_".

After all that, we're left with a variable named `$idleWindows` which is a newline-delimited list of the processIds of idle windows of the `screen` session.

We're nearly done!

## Open screen to appropriate window

`if [ -z "$idleWindows" ]; then screen -D -RR -p +; else screen -D -RR -p $(tr '\0' '\n' </proc/$(echo $idleWindows | cut -d ' ' -f1)/environ | grep ^WINDOW= | cut -d '=' -f2);fi`[^3]:

* `if [ -z "$idleWindows" ]; then ...` - if the `$idleWindows` variable is empty, then:
  * `screen -D -RR -S "$sessionName" -p +` - open a new window (`-p +`) in session `$sessionName` and attach to it. Else (if the `$idleWindows` variable isn't empty)...
  * ...`screen -D -RR -S "$sessionName" -p $(tr '\0' '\n' </proc/$(echo $idleWindows | cut -d ' ' -f1)/environ | grep ^WINDOW= | cut -d '=' -f2)` - the file `/proc/<processId>/environ` contains the environment variables of that process. From that, we can `grep` out the `WINDOW` variable (which is just a 0-indexed number), then `cut` it, to provide the value to pass to `-p` in the screen command (thanks again to the example in [this SO question](https://unix.stackexchange.com/questions/556594/how-do-i-find-what-process-is-running-in-a-particular-gnu-screen-window)!).

# This is a travesty, why would you do this?

A good question, to which my Signal autocomplete tried to provide an answer when I told a friend about this:

![Why-Would-You-Do-This](/img/Why-would-you-do-this.png)

Arguably, a better way to do this would be to create a script containing the appropriate logic (the filtering logic could probably be better expressed in a higher-level language!), deploy it to the appropriate hosts, and then call that script as the `RemoteCommand` (perhaps falling back to `screen -D -RR -p +` if it's absent). This would allow the logic to be split out nicely into appropriately named and commented functions. That script deployment is the rub, though - I'd rather "store" this logic in one place (my `~/.ssh/config` file) than have to handle deploying a script to every host I want to use this logic on. If I change my mind about that and want a more legible and debuggable source, I could add this script to the [pi-tools](https://github.com/scubbo/pi-tools) repo I use for setting up common tools on my homelab, or host the script on my NAS.

## No, really, why did you do this?

Most of the tasks I take on for this homelab project are motivated by a desire to learn. It's not so much that they're useful in-and-of-themself (as I said above - I could have stuck with the simple `screen -D -RR -p +` command which opens a new window, and closed the window as needed), but rather that they're a prompt to learn something new. And, indeed, in this case I've learned a good few things:
* The `$'...'` quoting syntax for bash that allows for double and single-quotes _within_ a single string
* The `[[:digit:]]` character class for `grep`. I could have _sworn_ it was `\d`, but that didn't work - maybe that's only for an older version of `grep`? Regardless, this spelling is more explicit.
* How to get the environment variables of a running process from `/proc/<processId>/environ`. I imagine that has a few nefarious purposes for black-/grey-hat applications...
* `pgrep` - here I've been, using `ps aux | grep` like some kind of _chump_!
* Hopefully, this has now cemented in my brain the `if [ -z "$variable" ]` syntax for checking emptiness - but I doubt it...
* `echo $$` to find the process of the current process

And a few things I have yet to learn:
* I'm still a bit puzzled about why `perl` appears to behave differently when called in an `ssh` command than when called on the machine itself. When called on the machine, referencing capture groups uses the `$1` syntax that I'm used to; but, when `perl` is used in a command in `ssh`, I needed to use `\1` instead (apparently, [there is no standard across engines to insert capture groups into replacements](https://www.rexegg.com/regex-capture.html#replaceg10) - and note that that article lists Perl as using both). I even checked that the `perl --version` in both contexts was the same. This is a real puzzler! Because of this, you'll notice I haven't used `perl` here even though it could have replaced and consolidated a few commands.
* As I called out in [an earlier section]({{< ref "#find-idle-sections" >}}), I don't yet know how I could have parsed the output of `sudo w` or information from `netstat` to extract the information I was looking for here. I'm also a little stumped about why [this questioner](https://unix.stackexchange.com/questions/556594/how-do-i-find-what-process-is-running-in-a-particular-gnu-screen-window) found `screen -Q` commands to be so slow, but they [appeared to take negligible time for me](https://unix.stackexchange.com/a/556640/30828).

[^1]: I had to use `xargs sh -c "<command>"` here, rather than the more normal `xargs <command>`, because the command contained semi-colons - without the `sh -c` wrapper, only the first part of `<command>` would have been passed to `xargs`, and the following parts would have been executed independently, outside the `xargs` context.
[^2]: While testing this, I ran into a problem - I was testing by running `ssh <host> <command>` from the command line, and I needed to enclose the command in quotes to prevent the `ssh` command only reading up until the first semi-colon and then stopping. However, I'd already used both double-quotes (to wrap the `sh -c` command) and single-quotes (within the `sh -c` command) - how could I combine both of those _and_ wrap them in a string identifier? Luckily, [this SO answer](https://stackoverflow.com/a/25941629/1040915) provided a solution - by wrapping a string in `$'...'`, you can use both double-quotes and escaped-single-quotes within it. This also required that the slashes in `\0` and `\n` be escaped, too - so it ended up looking like `\'\\0\'`. Not recommended - but good to know when necessary!
[^3]: There's another `fi` at the end of the full command to close the first `if` which created the session if it didn't exist.