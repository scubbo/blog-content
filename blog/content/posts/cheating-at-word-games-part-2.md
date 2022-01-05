---
title: "Cheating at Word Games: Part 2"
date: 2021-12-29T08:53:32-08:00
math: true
---
This is a sequel to my [previous post]({{< ref "/posts/cheating-at-word-games" >}}), where I laid out a Information Theoretical approach to algorithmically solving [Wordle](https://www.powerlanguage.co.uk/wordle/) puzzles.
<!--more-->
In that post, I considered whether there might be a strategy that takes a broader-view - rather than optimizing for maximizing information at _every_ step, it might be profitable to make a less-optimal guess1 if the combination (guess1+guess2), in combination are "better". One approach that intuitively makes sense is to select a pair of 5-letter words which, combined, comprise the ten most-common letters in the corpus. The two guesses combined will give a clear indication of which of those ten letters are present - and, hopefully, indicate a couple of their positions, too.

These pairs were [pretty easy to generate](https://github.com/scubbo/wordle-solver/blob/2d9279f8570154269ade68d56c0eeade74b24f1b/naive_solve_starter.py) - but, far from giving a single best option, there are 447 of them! Interestingly, my previous suggested first guess - "_roate_" ("_the cumulative net earnings after taxes available to common shareholders_", apparently) - was not in there. Apparently there is no word that is an anagram of the remaining 5 most-common letters, "_sincl_".

The next step would be to find the pair whose partitioning[^1] gives the greatest information. As a heuristic before doing that computation, it would be sensible to start with the pair which contains the single best guess from the previous approach. (I _suspect_ that this is equivalent to "_the guess which is most likely to have correct letters (rather than present ones)_", since correct letters are likely to be "_rarer_" and so to provide more information - but I haven't proven that yet). This might not be the best pair overall, if the second guess is significantly worse-than-average - but it's a good starting point!

That shakes out to recommending the pair of `(soare, clint)`, which has quite a pleasing poetic image of Hawkeye in flight :) now that I have two strategies described ("_always-locally-optimal_" vs. "_guess `soare`, then `clint`, then 🤷_"), I'm looking forward to finding a way to pit them against one another against an automated implementation of the game. I _suspect_ that they'll both reliably "win" in the same number of turns, so I'll either need to score them on their information/entropy properties (and probably have to dig out a textbook to make sure I'm doing that right), or construct some larger dataset for them to compete on.

(Check out the third post in this series [here]({{< ref "/posts/cheating-at-word-games-part-3" >}}))

[^1]: As described in the [previous post]({{< ref "/posts/cheating-at-word-games" >}}), each guess partitions the set of possible solutions into 125 subsets - one for each of the $5^3$ possibilities of `[first letter correct | first letter present | first letter absent] X [second letter correct | second letter present | ...`.
