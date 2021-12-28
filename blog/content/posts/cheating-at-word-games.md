---
title: "Cheating at Word Games"
date: 2021-12-28T07:18:24-08:00
draft: true
math: true
---

The other day, I saw the word game [Wordle](https://www.powerlanguage.co.uk/wordle/) going around on my Twitter feed. The game prompts you to guess a 5-letter word in a [Mastermind](https://en.wikipedia.org/wiki/Mastermind_(board_game))-like style - every letter in your guess is reported as being correct, as present (i.e. that letter occurs somewhere in the answer, but is misplaced), or absent).
<!--more-->
As is my way, I immediately started [thinking](https://twitter.com/jacksquaredson/status/1475207328039378945) about how I could use this as a prompt for a small tech project. I considered making a bot to play the game (using Greasemonkey and [KeyboardEvents](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent)), but the interface aspect is less interesting than the underlying strategy. What's the _best_ way to play the game?

There is a limited universe of "answer candidates"[^1]. Every time you guess, the set of answer-candidates is divided into (5^3=)125 different partitions, based on the 3 possible states each of the 5 letters in your guess might be in:
* All answers for which all letters in your guess would be entirely incorrect
* All answers for which the first letter of your guess is present-but-incorrectly-placed, and all other answers in your guess are incorrect
* All answers for which the first letter of your guess is correct, and all other letters are incorrect
* All answers for which the first letter of your guess is correct, the second is present-but-incorrectly placed, and all others are incorrect
* ...and so on...

This might be easier to understand with the following diagram:

![Wordle-Partioning](/Wordle-partitioning.drawio.png)


(Examples generated with [this script](https://github.com/scubbo/wordle-solver/blob/main/example_generator.py))

The game’s response to your guess indicates which partition the answer lies in. Assuming that you haven’t guessed the word, you can then repeat the process with a different guess - your guess will tell you which “sub-partition” within that partition the word lies in, and so on. With each guess, you are gaining information that is used to reduce the set of possibilities The strategy, then, is to determine which words you should pick to maximize the information gained at each step[^2].

Information is maximized when the size of the indicated partition is minimized[^3] - the smaller the indicated partition, the less uncertainty exists about which candidate is the actual answer. However, since we don't know in advance which partition will be indicated (because we don't know the answer), we instead have to minimize the _[expected](https://en.wikipedia.org/wiki/Expected_value)_ partition size for all possible answers. For a given partioning strategy, we can calculate the expected partition size with the following (where "_part(x)_" is "_the partition that contains (candidate answer) x_", $ \mathbb{P} $ is the set of partitions, and $ \mathbb{C} $ is the full set of candidate answers)[^4]:

$$
\begin{aligned}
E(size\ of\ partition) &= \sum_{c \in \mathbb{C}} \mathcal{P}(c\ is\ correct) * | part(c) |\newline
&= \sum_{p \in \mathbb{P}} \sum_{c \in p} \mathcal{P}(c\ is\ correct) * |part(c) |\newline
&= \sum_{p \in \mathbb{P}} \sum_{c \in p} \mathcal{P}(c\ is\ correct) * |p|\newline
&= \sum_{p \in \mathbb{P}} |p| \sum_{c \in p} \mathcal{P}(c\ is\ correct)\newline
&= \sum_{p \in \mathbb{P}} |p| \sum_{c \in p} \frac {1} {|\mathbb{C}|}\newline
&= \sum_{p \in \mathbb{P}} |p| * \frac {|p|} {|\mathbb{C}|}\newline
&= \frac {1} {|\mathbb{C}|} \sum_{p \in \mathbb{P}} |p|^2
\end{aligned}
$$

Therefore, we can maximize the information gained at each guess by minimizing the sum-of-squares of the sizes of all resultant partitions.



[^1]: we can figure out exactly what this is by taking a quick peek at the code - or, we could infer that it exists by noting that there are a large-but-finite number of ways of arranging 26 letters in 5 positions (a little less than 12 million), or a smaller-but-still-very-large number of actual five-letter words. The actual list of potential answers for Wordle includes 2,315 words, and there are 10,657 words that you are allowed to guess (that is - there are 8,342 words that you're allowed to guess for information, but that cannot possibly be the answer)

[^2]: This is a naïve implementation: there _might_ be a better strategy which is not locally-maximal, but which generates more information by coordination between the steps. For instance, there might be a choice at Step 1 that results in larger-than-optimal partitions, but where each partition is then more amenable to sub-division in Step 2. My intuition is that this isn’t the case for this problem, but I’m open to disagreement!

[^3]: It’s been a _while_ since I’ve studied Information Theory, so I might be misusing some terms. Please do feel free to correct me if so!

[^4]: LaTeX formatting added to this blog courtesy of [this guide](https://mertbakir.gitlab.io/hugo/math-typesetting-in-hugo/).