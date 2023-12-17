---
title: "Almost All Numbers Are Normal"
date: 2023-12-17T17:23:09+00:00
math: true
tags:
  - mathematics
extraHeadContent:
  - <link rel="stylesheet" type="text/css" href="/css/table-styling-almost-all-numbers.css">
---
"Almost All Numbers Are Normal" is a delightful sentence. In just five words, it relates three mathematical concepts, in a way which is true but misleading - the meaning of the sentence is almost exactly the opposite of what a layman would expect.
<!--more-->
## Numbers

The intuitive conception of "_numbers_" if you ask someone to simply "_name a number_" are the natural numbers $\mathbb{N}$ (0[^is-zero-a-natural-number], 1, 2, 3, ...), or the integers $\mathbb {Z}$ (... -3, -2, -1, 0, 1, 2, 3, ...). [Of course](https://xkcd.com/2501/) most folks are familiar with the rationals $\mathbb{Q}$, though probably by the name of and through the lens of "fractions" rather than the more mathematically-precise objects - and even those only scratch the surface of the full set of [real numbers](https://en.wikipedia.org/wiki/Real_number) $\mathbb{R}$ [and beyond](https://en.wikipedia.org/wiki/Complex_number#Generalizations_and_related_notions).

There are plenty of ways to conceptualize some of these sets of numbers - typically as the unique (up to isomorphism) structure satisfying some particular set of axioms like [Peano's](https://en.wikipedia.org/wiki/Peano_axioms#Set-theoretic_models) or [Dedekind's](https://en.wikipedia.org/wiki/Dedekind_cut) - but for the purposes of this post, I want to consider the reals[^limitation-of-consideration] as an infinite sequence[^what-about-the-decimal-point] of digits 0-9, or equivalently as a function $f: \mathbb{N} \to {0, 1, 2, \cdots 9}$. That is, the number `7394.23` is equivalent to the function partially represented by the following table:

| Index        | Value     |
|--------------|-----------|
| 1            | 7         |
| 2            | 3         |
| 3            | 9         |
| 4            | 4         |
| 5            | 2         |
| 6            | 3         |
| 7            | 0         |
| 8            | 0         |
| 9            | 0         |
| ...          | ...       |


I say _partially_ represented, because of course this table could continue infinitely - for any index greater than 6, the function's value is 0: [$\forall n > 6, f(n) = 0$].

This way of describing numbers focuses less on their value, and more on their written representation - it stresses the ability to ask "_what is the fifth digit of this number?_" much more than the ability to ask "_which of these two numbers is bigger?_". This focus will be justified in the next section.

## Normality

The word "normal" has lots of domain-specific meanings in mathematics, many of them related to one of two concepts:
* **orthogonality** - that's fancy mathematician speak for "_being at 90-degrees to something_"[^orthogonal]. For instance, we could say that a skyscraper is orthogonal to, or normal to, the ground, because it points straight upwards and the ground is horizontal.
* of or related to the **norm**, which itself is a function that assigns a length-like value to mathematical objects.

In particular - I don't think I've _ever_ heard the term "_normal_" used in its layman's sense of "_standard, expected, regular, average_"[^term-of-art]. I guess mathematicians don't think it's very normal to be normal.

In number theoretic terms, a [normal number](https://en.wikipedia.org/wiki/Normal_number)[^absolutely-normal] is one in which all digits and sequences of digits occur with the same frequency - no digit or sequence is "favoured". The string of digits looks like it could have been the output of a random number like coin-flipping (for binary digits) or repeatedly rolling a d10.

It's pretty easy to immediately see that no number with terminating decimal expansion (which includes all the integers, and all fractions with a denominator of a power of 10) are not normal - if the sequence of digits starts repeating 0, then 0 is "favoured", and the number is not normal. A little more thought shows that every rational number (every fraction) is abnormal - either the division terminates (and the decimal expansion continues `000...`), or the decimal expansion repeats (and so the repeated-string is "favoured", and any string which didn't appear before point that is absent).

### Corrolary of normalcy

A fun property of normal numbers is that, because all subsequences are "_equally likely_", and because they are infinite non-repeating sequences, any given sequence of numbers _must_ exist somewhere in them. Since any content that is stored on a computer is stored as a sequence of numbers, this implies that any content you could imagine - your name and birthday, the Director's Cut of Lord Of The Rings, a sequence of statements which prove that almost all numbers are normal - exists somewhere within each of them.

The trick would be _finding_ it...

## Almost All

Along with "normal", this is a common term which has a specified mathematical meaning - although, in this case, the meaning _is_ intuitive[^normal-meaning], just formally-defined.

A property is said to hold for "_almost all_" elements of a set if the complementary subset of elements for which the property does _not_ hold is negligible. The definition of negligible depends on the context, but will typically mean:
* A finite set inside an infinite set ("_almost all natural numbers are bigger than 10_" - because the set of numbers smaller-than-or-equal-to 10 is finite, and the set of naturals is infinite)
* A [countable](https://en.wikipedia.org/wiki/Countable_set) set inside an [uncountable](https://en.wikipedia.org/wiki/Uncountable_set) one, or generally a "smaller" infinity inside a bigger one.

This is probably the least surprising of the three concepts, but it does take a while for Maths undergrads to get their head round the co-feasibility of the statements "_P(x) is true for almost all x in S_" and "_P(x) is false for infinite x in S_".

## Putting it all together

So, putting it all together - "_almost all numbers are normal_" could be roughly translated as "_when considering the set of functions which map from $\mathbb{N}$ to ${0, 1, 2, ... 9}$, a negligible set of those functions result in sequences which have subsequences roughly evenly distributed_". Which is about as far as you could get from the results you'd get if you asked a layman to name some normal numbers - small natural numbers!

(I'm not actually going to present a proof of that fact here - I vaguely recall the shape of it, but being over a decade out of study, it's a little beyond my capability to present understandably. There are some reasonably accessible proofs [here](https://arxiv.org/pdf/2102.00493.pdf) and [here](https://www.colorado.edu/amath/sites/default/files/attached-files/math21-8.pdf) if you're interested!)

[^is-zero-a-natural-number]: If you have strong opinions on whether 0 is a natural number, you probably already know the rest of what I'm going to cover in this post.
[^limitation-of-consideration]: I don't think it's a cheat to limit my consideration to normal numbers here, since the concept of normality only applies to normal numbers. For any non-real number, the answer to "_is this normal?_" is `null`, `undefined`, or "_[mu](https://en.wikipedia.org/wiki/Mu_(negative)#Non-dualistic_meaning)_".
[^what-about-the-decimal-point]: For reasons that will become clear as I go on to talk about normality, we're ignoring the decimal point. That is, $123 \equiv 1.23 \equiv 0.000123$ for this discussion. Just trust me.
[^orthogonal]: Again - if you know enough to know why this statement is incorrect, you also know enough to know why I'm glossing over the complications.
[^term-of-art]: yes, I did intentionally pick words here which all have their own mathematical definitions. Language is fun!
[^absolutely-normal]: I'm only discussing base-10 here. A number which is normal in all integer bases >= 2 bears the wonderful label "_absolutely normal_".
[^normal-meaning]: that is - it has the normal meaning 😉
