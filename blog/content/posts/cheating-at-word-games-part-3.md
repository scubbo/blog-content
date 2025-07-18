---
title: "Cheating at Word Games: Part 3"
date: 2022-01-05T07:50:29-08:00
tags:
  - wordle
---
The third in a series on [Wordle]({{< ref "/posts/cheating-at-word-games" >}}).
<!--more-->
I created a [User Script](https://github.com/scubbo/wordle-solver/raw/main/wordle-assistant.user.js) that tells you how many words you have "narrowed it down to" at each point in the guessing - and, once you've solved the puzzle, tells you what those words were (if there aren't too many to display). I plan to later introduce a feature that tells you the "score" of your guess (calculated as "_the inverse of the expected size of the partitions of the answer space_", as in my [previous post]({{< ref "/posts/cheating-at-word-games" >}})) and what the optimal guess would have been for even partitioning. Pull requests (and/or comments on my probably-horrendous JavaScript) welcome! In the [lovely non-intrusive spirit of the Wordle game itself](https://www.nytimes.com/2022/01/03/technology/wordle-word-game-creator.html), the script doesn't "_phone home_" to measure the number of users - though, if you do end up using it and enjoying it, I'd love for you to let me know!

To install it, you'll need either [Greasemonkey](https://addons.mozilla.org/en-GB/firefox/addon/greasemonkey/) (for Firefox) or [Tampermonkey](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo?hl=en) (for any other browsers, including Chrome). Install either of these extensions, navigate to the [User Script itself](https://github.com/scubbo/wordle-solver/raw/main/wordle-assistant.user.js), and you should be prompted to install it.

Developing this script really helped me to recognize that my information theoretic viewpoint of "_reducing the expected size of partitions_" wasn't aligned with how humans solve these puzzles. The key difference is that a human is trying to _think of_ a word, not to select it from an authoritatively-known and enumerable list. For a human there is a difference between "_having knowledge in your brain_" and "_being able to bring it to mind_". That is to say - a clue that fixes a letter with a `correct` evaluation is more useful to a human than one which greatly reduces the partition-space, because that fixed letter will act as a solid prompt that will help the player bring the appropriate word to mind more easily. Maybe I'll develop another scoring strategy that incentivizes correct letters - though it might be subjective as to how heavily they should be weighted.

(Props to [@mastergeorge](https://twitter.com/mastergeorge/) and [@NotBrunoAgain](https://twitter.com/NotBrunoAgain/) for letting me bounce ideas off them during development)
