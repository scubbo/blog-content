---
title: "The CrAbs Fallacy"
date: 2022-04-03T12:25:57-07:00
tags:
  - web3
---
First blog post in a long time. This was caused by combination of four things (most of which I hope to address in more detail in following blog posts):
* My home network starting misbehaving and I was focused more on fixing that than blogging (the first rule of homelabbing - whatever you mess with with, your living partners need to be able to access the Internet, and to work the lights and heating!
* I finally took the plunge in moving this blog from fully AWS-hosted to self-hosted.
* I got Laser Eye Surgery and was recovering from that (probably won't be blogging about that, not much more to say!).
* I started writing a post to articulate my confusions or uncertainties about web3, with the intention of understanding it better.
<!--more-->
It's the last of those topics that I want to dive into today. My original Crypto-understanding post ended up expanding out of control, so I'm just focusing on a small area today - a fallacy I've seen many crypto-enthusiasts commit.

## Preamble

Before I do, let me establish my position - despite my skepticism, I really do resonate with many of the ideals professed by the web3 movement:

* decentralization
* freedom to use tools and services how you want rather than how their creators intended
* equitable instant worldwide money transfer
* democratization of raising capital, dismantling of monopolies
* better user experience through competition

Unfortunately I still haven't seen any projects or proposals that actually seem feasible on their own, let alone strong enough to overcome existing incumbents (and the significant legal apparatus set up to protect them). I criticize not because I want web3 to fail, but because I want to be convinced that it can succeed.

## The CrAbs Fallacy

The Crypto Absolutism Fallacy, or "_CrAbs Fallacy_", applies when a proponent of a system suggests that some condition will be improved, without recognizing that that only happens if the system exists in isolation and/or if every actor is only using that system; if actors can use that system _and other similar systems_, then the condition actually stays the same or worsens.

Some examples:

### Corporations can't sell your data

The prototypical Blockchain selling point is "_services won't be able to sell your data unless you give them permission to do so_". In a Crypto-absolutist world, when an actor buys access to your personal data, the read-permissions for some blockchain-stored data are updated to allow that actor access, but they are not able to use that permission to grant any _other_ actor read-access - so, granting Actor A access to our data means that _only_ Actor A can access it.

All well and good - except, this assumes that the data can only exist on, or be accessed via, the blockchain. If you can read data, you can copy it. If you can copy it, you can persist it to your own non-Blockchain storage where _you_ control the permissions. And from there, you can sell it on to whoever you like. Ironically, the "right-clicking" response to NFTs [^1] clearly illustrates the issue, here - once you've given someone access to something, you cannot then control what they do or how they use it.

There are some interesting projects like [this](https://news.ycombinator.com/item?id=30698215) that allow one to carry out operations on data without having actual access to the data (by submitting the job-to-be-run to a controlled system and only being allowed to access the output) - but, again, we return the classic refutation of web3 projects, "_You don't need a blockchain to do that (and introducing one just adds orders of magnitude of complexity)_"

### Crypto avoids middle-man fees

I've [seen it claimed](https://news.ycombinator.com/item?id=30623449) [^2] that crypto is better for consumers because traditional methods of fund transfer include a premium guarding against the risk of chargebacks. Leaving aside the various advantages of a regulated financial system [^3], this presupposes that those fees would go away. It seems much more likely that a profit-motivated fund-transfer agent would just charge the same price for both methods, and pocket the difference for the crypto method.

"_But then a competitor would spring up who charges less for the crypto-based transfer_, says the Crypto-enthusiast, forgetting that [Economic Moats](https://en.wikipedia.org/wiki/Economic_moat) exist. If given the chance to transfer money with an established, trustworthy, commonly-used intermediary for negligible fees, or for a new no-name up-and-comer for no fees, I'll pick the former every time. Big businesses conducting thousands of transactions a day and with the legal clout to enforce contracts and SLAs might experiment with the latter - and then, again, they'll pocket that difference and the consumer will see no benefit.

So - yes, if Crypto had sprung up from nothingness before an existing financial-transfer-mechanism existed, it would have led to lower transfer costs - but it didn't, and it won't.

### Money Laundering

One of the few crypto-enthusiasts who I greatly respect[^4] [recently claimed](https://twitter.com/dystopiabreaker/status/1510410214834511876) that crypto is uniquely poorly-suited to money laundering because all the transactions are out in the open. In a Crypto-Absolutist world where all transactions take place on the blockchain, that is indeed true - but, in reality, two things can sully this vision:

* Being able to trace the transactions via intermediaries doesn't mean you can actually trace the flow of value. If A1 sends 2ETH to L, A2 sends 3ETH to L, L sends 1ETH to B1, and L sends 4ETH to B2 - then who has paid whom? Unless the "_when you receive payment X, send payment Y_" instructions were also recorded on the blockchain as a [smart contract](https://en.wikipedia.org/wiki/Smart_contract) (and, although we've seen some spectacularly stupid Crypto-criminals, this would really take the cake), you can't actually trace which of A1 or A2 is paying B1 or B2.
  * OK, so that just makes Crypto _as bad_ as traditional finance, not worse - but then consider the fact that, absent the friction of setting up a traditional banking account, you can create thousands of those entities and intermediaries with a simple script. Try tracing a fraudulent transaction through millions of obfuscating layers and transactions.
* Not all transactions need to go via the blockchain. You can create an airgap by extracting value from one wallet to fiat, and then deposit it in another wallet.
  * Again, _prima facie_ this simply means that Crypto is _as bad_ as traditional finance, no worse (you can extract money from one bank account in cash and deposit it in another) - but, the task of finding a sketchy unlicensed unmonitored individual who will exchange your crypto for fiat is _much_ easier than finding a sketchy unlicensed unmonitored bank account that will let you withdraw cash.

## Naïve trust

This last example seems to smack of another common crypto-fallacy, which I haven't come up with a snappy name for yet - the assumption that all actors are acting in good faith (ironic, for a community that has done laudable work in developing Zero Trust mechanisms). If everyone promises to play by the rules and use the system how it's intended _except_ for the fact that they are money laundering, then a sequence of transactions on crypto systems (with a small number of wallets/intermediaries, and with no fiat-airgaps) is indeed easier to trace. But one thing you can say about money launderers is that they are willing to break rules. Maybe this short-sightedness comes from the development of Zero-Trust systems - once you start thinking in terms of "_given these assumptions, how can we generate proofs without sharing this private knowledge?_", and get so wrapped up in that thinking that you forget that the initial assumptions don't apply universally in the real world.

Another example of this "_our system is superior if everyone is well-behaved_" thinking is in regards to scams and frauds. Crypto-enthusiasts often point to the inefficiencies of traditional finance's legal structures, and declare that crypto's fast[^5] smooth[^6] actor-to-actor transactions are superior. And, indeed, that's true - so long as you trust the person on the other end of the transaction. If you send some crypto to a wallet address to buy physical goods, and those goods don't show up, what recourse do you have? None. In fact, the only time that you can be sure that sending crypto-currency will result in the outcome that you hope is when you're interacting with a [Smart Contract](https://en.wikipedia.org/wiki/Smart_contract) (and, even then, you need to have the technical skill to read and understand the code) - and we're back to the CrAbs fallacy once again. Shuffling virtual bits around is fun and all; but, at the end of the day, you need to buy food and pay rent, too. The moment you have to pay someone to do something in the real world, you need a way to ensure that they will keep their end of the bargain - and, inevitably, that reduces to "_someone with a big stick (i.e. the government) supports you in your claim_". If you are intentionally circumventing the frictions and requirements of oversight, you cannot also expect to enjoy their benefits.

## Conclusion

Look, don't get me wrong. I really truly do _want_ a lot of crypto/web3 as it is often described to succeed. It pisses me off that big established power brokers are able to manipulate markets (or trade privately on different markets entirely), rent-seek by virtue of size, or get unfair trading advantages to further cement their position (hi GME-Apes!). It feels philosophically offensive to me that using basically any Internet service today rquires giving up a staggering amount of personal information that is then used to tailor advertisements to influence me into engaging in commercialism. I _want_ these practices to end, and I want to see better, fairer, more-equitable technical and social systems replace them. But a lot of crypto speculation fails to recognize that it's not being developed in a vacuum, and those same bad actors will seek to manipulate or profit from web3 systems just like they did the web2-ones, and they have become exeedingly efficient at it. If your tactic for preventing abuse includes "_and you have to promise to only use this system and no others_", abuse will just go outside your system, and the combined hybrid-system might actually make things worse.

[^1]: The "Right-clicking" response, as amusing as it was, was flawed - it was responding to a different claim than the one being made. NFTs never claimed to be about enforcing that no-one on the planet could ever display or copy the content to which the NFT pointed, they were merely intended to prove ownership of an abstract digital concept. This has its own issues (not least - if you want to use that ownership to enforce ownership rights like royalties, how do you ensure that the minting authority has correctly checked ownership of the original asset, and didn't just mint the NFT spuriously?) - but I'll get to those in a later post.

[^2]: I don't know if it's possible to paste a HN link that provides context (parent comments). If it's possible, please let me know!

[^3]: Such as protection against fraud. In a sense, the chargeback-protection fees you pay are analagous to the taxes paid to a support a Fire Department. You might not personally benefit from the services being funded by those fees, but society functions better when they exist!

[^4]: Because she tries to articulate _why_ she thinks crypto is worthwhile, superior, misunderstood, etc., rather than mindlessly parroting "NGMI"-like catchphrases. She's a big part of my inspiration for actually trying to engage with, understand, and critique crypto, rather than just writing it off because other people told me to.

[^5]: \[Citation Needed\] - at the [time of writing](https://www.statista.com/statistics/944355/cryptocurrency-transaction-speed/), transaction times for Bitcoin and Ethereum were 40 and 6 minutes, respectively. Admittedly, the perceived-as-instant transactions on traditional finance systems are due to some [creative bookkeeping](https://news.ycombinator.com/item?id=30622861) - but _the consumer doesn't know or care_.

[^6]: Also \[Citation Needed\] - I haven't set up my own self-hosted wallet, but I've seen plenty of smart technical folks struggle with it in a way that makes me lack confidence that the average non-technical user would be able to. Coinbase etc. are a little smoother, but surely a centralized system [isn't real Crypto](https://en.wikipedia.org/wiki/No_true_Scotsman)?
