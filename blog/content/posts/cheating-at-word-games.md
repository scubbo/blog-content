---
title: "Cheating at Word Games"
date: 2021-12-28T07:18:24-08:00
draft: true
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


TK it might not actually be best to guess from among the possible words - when you know a given letter, it might be better to guess a word that _doesn't_ have that letter, in order to get more info about letters that do/don't exist elsewhere in the word

[^1]: we can figure out exactly what this is by taking a quick peek at the code - or, we could infer that it exists by noting that there are a large-but-finite number of ways of arranging 26 letters in 5 positions (a little less than 12 million), or a smaller-but-still-very-large number of actual five-letter words. The actual list of potential answers for Wordle includes 2,315 words, and there are 10,657 words that you are allowed to guess (that is - there are 8,342 words that you're allowed to guess for information, but that cannot possibly be the answer)