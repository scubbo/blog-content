---
title: "Criticisms of Web3"
date: 2022-06-15T16:05:45-04:00
tags:
  - web3
---
I want to start this article by clarifying that I _want_ web3[^1], as commonly proposed, to succeed. The ideals that the web3 movement often espouses - transparency of web service logic, privacy and personal control of user data, anti-monopoly - are ones with which I resonate[^2]. Unfortunately, there are several common questions that current projects seem unable to answer, leaving me skeptical that they will succeed.
<!--more-->
(Aside: I started writing this post before the current calamitous freefall of cryptocurrencies, which may render unnecessary many of the criticisms below as the shaky projects will have been abandoned. Still - I've started, so I'll finish)

I'm writing this post primarily to articulate the questions for myself, to state them clearly and to test them for coherence, watertightness, and importance. Secondarily, I hope this will serve as a reference for discussion - instead of having to re-state a question or criticism afresh, I can link to a description here. I flatter myself to think that web3 proponents might be able to use this post as a checklist to ensure that their project doesn't have any _obvious_ flaws[^3].

Most of these questions assume that the project aims to reach some critical mass of size. This is a particularly reasonable assumption for projects that have a social component (there's no point posting on a social network if your friends aren't there!), but also applies to general economic considerations.

# Questions

## Soft Questions

These are questions that are not deal-breakers, but that can highlight a potential point of friction or concern in the project.

### User complexity

How complex will it be for a user to understand and run the components necessary for the system? This presents a barrier to entry - if only geeks, nerds, and enthusiasts are able to use your system, then it's unlikely to hit critical mass.

This is a soft question because it can be addressed with UI/UX improvements, by "hiding" the complexity under user-friendly components. Most internet users couldn't tell you how TLS/SSL certificates work, for instance, and yet they benefit from them every day.

### Fork-resiliency

How resilient will this system be to chain-forks; large-scale consolidated actions in which chain participants agree to ignore/rewrite a chunk of history?

This is categorized as a soft question, despite the potential large impact ("_if the chain can be forked at any time, then there is no guarantee that my assets/ownership/stake are durable and reliable_"), because a project owner could argue that this situation is no worse than the current web2 situation - InsertLargeServiceProviderHere co. can arbitrarily decide that you are not welcome on their platform, and unilaterally take whatever actions they wish by seizing your digital assets or ejecting you from their system. Personally, I believe we're not yet at a state where the stability of large blockchains is more trustworthy to me than than the reputational damage to TwitAmaGooPpleBookSoft of such arbitrary bootings - but it probably won't be long before they're comparable.

### Abuse-resiliency

How resilient will the system be to hacks, phishing, fraud, bugs, etc.? If a transaction occurs on the system that can be proven to have been unintentional or malicious, can it be reversed?

This is a thorny question - the "_code is law_"[^4] attitude I perceive in many web3-thusiasts seems to imply a rugged individualist "_if you get scammed, you deserve it - that's the price you pay for the benefits of unregulated liberty_". Perhaps this is why [basically any web3 or crypto story](https://web3isgoinggreat.com/) ends with a rugpull, a major hack, or some combination of the two.

Note that this is a dual to the question above. Abuse-resiliency is, by definition, the ability to revert transactions that are determined to be "bad" - that is, rewriting history. In order to do so, the project must give up a commonly-touted benefit - the lack of a central dictatorial authority who can compel action or override preferences. A quorum of users who can initiate a fork always form such a central authority, but it could(?) be possible for a system to be built such that an operation could be compelled by a trusted super-user without requiring a full fork ("_I, user `abc`, hereby authorize user `def` to take control of my account in the following situations and with the following constraints: ..._"). Each system('s steering commitee) would have to decide for itself whether the abuse-protection of such an override is worth the loss of liberty it implies. Hence, this is a soft question - some users might _want_ a rugged, wild-west, "_do what thou wilt be the whole of the law_" environment, while others might _want_ some protection from scams.

### Data Ownership

"_You own your data_" is a common refrain of web3 systems. However, this is a fuzzy statement that could cover a multitude of claims, given the uncertainty about the key terms "_own_" and "_data_":
* Does "_Ownership_" mean:
  * that you have final say in the usage, sale, and distribution of the data? If so - how can you prove that the service _isn't_ selling your data, or that 3rd-parties to whom you provide access are not saving-and-selling-on that data.
  * that you will always share in any profit derived from usage/sale of your data?
  * that you will always be able to extract the data about you from the system? This is one of the more reasonable and justifiable claims (though...how would you prove that the data is complete? How could a user prove that data is missing without knowing what that apparently-missing data _is_?) - though, frankly, for countries that have [GDPR](https://en.wikipedia.org/wiki/General_Data_Protection_Regulation) or an equivalent, this isn't actually much of a novelty (see ["Why do you need a blockchain/decentralization for this? Does portability/scarcity even make sense?"]({{<ref "#why-do-you-need-a-blockchaindecentralization-for-this-does-portabilityscarcity-even-make-sense">}})).
* Is "_your data_":
  * Just the data that you provide to the system - your preferences/settings, your posts, your connections (follows/friends/circles), your structures (playlists) - or also...
  * ...the data that is generated as an output of your usage of the service - your [Data Exhaust](https://en.wikipedia.org/wiki/Data_exhaust)? This encompasses simple things like "_play counts of songs_", or complex inferred data like "_customer genre tastes derived from play counts_" or "_customer marketing segment derived from click-through rates_".

I think that a lot of web3 systems do a (possibly-intentionally?) terrible job of clarifying this ambiguity. Users think that they're being promised a beautful utopia where your data never gets sold or used for marketing and you can profit from your usage of the system just as much as the service itself does, where in fact the promise is the minimal coverage of "_you can always extract from the system whatever you put into it (but not anything we calculate from you) - and forget about any profit-sharing_"

## Hard Questions

These are questions that, I believe, are fatal to a web3 system if they cannot be answered satisfactorily.

### Why would a service implement this?

Most web3 proposals make the experience significantly better for users. This is usually at the cost of some lost-advantage for the service provider - less information, less monopoly power, and so on. A particularly egregious example (often used in the context of NFTs in music[^5] or gaming[^6]) is the case where a user buys content on service A, and then expects to be able to consume that content on service B via ownership expressed via an NFT or similar. Assuming that the service isn't profiting from the customer's use _of_ the service (see ["Data Ownership"]({{< ref "#data-ownership">}})), why would service B permit this?

This question can be split into two sub-questions:

#### Why would an existing service integrate with this?

Most existing web services benefit from an economic moat - there is friction in moving away from the service, since a customer has built up an identity (preferences, posts, connections) on the service that cannot be exported. This conveys an economic advantage - the service can extract more profit-per-customer because the friction forces a customer to endure a level of service that would otherwise cause them to stop using the service, or switch to a competitor. This is a situation that many web3 projects aim to counteract; to increase competition (and thus, quality of service) by reducing the friction of moving an account to a different provider.

However, we must ask why any existing provider would willingly integrate with a system that destroys an economic advantage that they have built up. They would only do so when there is a net economic advantage to the integration (a _large_ one, because this integration with an outside system would presumably be more complex than working with their own systems, and would provide value to a competitor) - and that, presumably, would only happen when the user-base of the low-friction system is large enough to represent a significant asset. A web3 system that _needs_ to integrate with existing providers in order to succeed is therefore stuck in a chicken-and-egg situation - it cannot reach critical mass until existing providers integrate with it, but existing providers will not do so until it has grown sufficiently large.

#### Why would a new service implement this?

Consider, instead, a system that is "_starting from scratch_" - not attempting to integrate with existing providers, but providing value in-and-of-itself. Still, here; given that there is an economic advantage to "building moats", why _would_ a new system choose to give up that advantage?

(One very reasonable response here is "_because we plan to set the expectation in this product-space that web3-openness is table-stakes, so that users will reject non-open competitors; and users will be so impressed by our differentiated features that they *choose* to keep using our service rather than moving to another open competitor_". If so - that's great! I am not saying that these questions are fundamental flaws in web3 _per se_. Rather, they are questions that a project must be able to answer in order to appear feasible. If you have good answers - good for you, I look forward to seeing your success!)


### Why would a user migrate to this/stay with this?

A service cannot survive without customers. Customers evaluate a service on two parameters; quality and price[^7]. In order to convince a customer to move from an existing service to this new one, the combination of quality-at-price must not only match the existing service, it must exceed it by enough to overcome the friction associated with migrating.

One point on which Web3 services pride themselves is that their systems are open, decentralized, and privacy-respecting. These are admirable properties! But they have associated problems:
* If the service isn't selling customer data or serving ads, then [the customer is not the product](https://techhq.com/2018/04/facebook-if-something-is-free-you-are-the-product/) - this makes it pretty likely that the service will not be available for free (this is further supported by many blockchain-based systems that require a payment-per-interaction - a rude surprise for customers who are accustomed to internet interactions being free!). Migrating from a free service to a paid one requires an extraordinary surplus of quality.
* Frankly, most customers don't seem to care much about privacy: witness the fact that many continue to use Web2.0 Social Media despite the repeated revelations about privacy abuses. From this, we can conclude that "_this service respects your privacy_" is _not_ a particularly compelling feature for the average customer[^10] - it's a nice-to-have, but the service will need to provide a slew of other compelling features to overcome the migration-friction _and_ the price-increase-from-free.

So - you need features in order to attract customers, and you need a _lot_ of features to attract customers from a free service to a paid one. But the situation is even worse than that for nascent web3 services:
* in order to build those features, you need money
* to get money, you need either paying customers (but you don't have them yet) or investors
* those investors will expect a return on their investment

This is not a problem that's unique to web3-based services, by any stretch! "_Launch fast with a compelling offering, acquire a critical base of customers, then pivot to profitability_" is a tried-and-true Silicon Valley strategy. However, it may be a little more difficult to sustain when two key pillars of your offering are:
* privacy - which precludes you from two key sources of income that don't come out of your customers' wallets; ads, and selling customer data.
* low-friction of migration between services - so, you cannot rely on economic moats; your service will live or die on whether its features are better than a competitor's.

At the risk of repeating myself - this is not a fatal gotcha! There are certainly imaginable ways that a web3 service could navigate these requirements, by building features that attract and retain customers while achieving profitability. But this certainly seems like a harder product problem in a space where you cannot profit indirectly from customers, and where the friction of moving to a competitor is low.

### Why would real-world authorities respect this?

Some projects aim to represent real-world ownership or entitlement as digital resources, with the promise that transacting on (validating, transferring) those ownerships will be faster, smoother, and cheaper (see "_Code Is Law_"[^4]). That's all very well - but, what will you do when you need to enforce that ownership in the real world?

Take the case of homeownership. In part, the value of a traditional home title document is that it is backed by the authoritarian power of the establishment; that, if someone is squatting in your home, you can have confidence that Men With Guns will come and back you up in your claim that they should stop doing so. If your aim is to build a new system of determining ownership, you have one of two choices:
* Reject the authority of the existing establishment and declare your system to be the Truth. Enjoy attempting to explain that to the aforementioned Men With Guns.
* Attempt to convince the establishment that they should respect your system as an alternative/supplementary source of ownership truth. This then reduces to a ["Why would an existing service integrate with this?"]({{<ref "#why-would-an-existing-service-integrate-with-this">}}) question - why would the existing bureaucracy a) put in the work, and b) give up their profit margin (or government grants, or whatever), by adopting your system?

Again, potential satisfying answers to this question exist, including buying-out the existing bureaucracy or offering them a cut of the profits. This is not a global-gotcha, it's just an awkward question that often goes unanswered.

### How do you enforce that the system represents reality?

Many systems attempt to represent real-world entitlements in a digital form. For instance, some NFT systems represent ownership of a real-world piece of media or art[^8]. In such systems, it's important that the representation is accurate and reliable; if it cannot be trusted, then it is not a valuable system.

This problem is particularly important at the point of creation of a digital resource. For a resource with a chain-of-custody that can be confirmed in some trustworthy source (potentially, but not necessarily, a blockchain), you can be sure of "_where it came from, and who transferred it, when_", and thus hopefully confirm that those transfers correspond with transfers of the real-world entitlement (though, see the next paragraph) - but this only inductively proves "_if the resource originally represented the entitlement, then the resource *now* represents the entitlement_". It's missing the crucial [base case](https://en.wikipedia.org/wiki/Mathematical_induction) - "_did the resource represent the entitlement at the time that the resource was created?_". Without this proof, you end up in the absurd situation where anyone can mint an NFT "_proving_" ownership of (say) the Brooklyn Bridge.

Note that this question is related both to ["Why would real-world authorities respect this?"]({{<ref "#why-would-real-world-authorities-respect-this">}}) (existing authorities will be unlikely to respect a system that is unreliable) and to ["Abuse-resiliency"]({{<ref "#abuse-resiliency">}}) (abuses to the system will most likely be intended to transfer ownership away from their "rightful" owner, thus making the system an inaccurate reflection of reality)

### Why do you need a blockchain/decentralization for this? Does portability/scarcity even make sense?

Don't get me wrong - [blockchains](https://en.wikipedia.org/wiki/Blockchain) are fascinating data structures, with many interesting and potentially-useful properties. But they're also overkill if you don't _need_ or benefit-from those properties. Similarly, the ability to represents ownership on a distributed ledger in a system-agnostic way is very cool - but, if your use-cases only ever include transferring ownership within systems owned by your own company, you have just introduce a _ton_ of complexity to achieve an outcome that is indistinguishable from "_a row in a traditional database_".

# Conclusion

To repeat - my articulation of these questions does not mean that I think that web3 is doomed, nor that I inherently oppose it. I responate with many of the ideals professed by many web3 projects, and I really hope that projects exist that can answer these questions and provide value to users while avoiding significant environmental impact. This article is a framework for evaluating common flaws in proposals, _not_ a comprehensive takedown of all of web3.

[^1]: Definitions are nebulous and various, so for this purposes I'm categorizing web3 as "_any project which opposes or inverts the monopolistic power of web service providers, by decentralizing components, reducing lock-in, increasing competition and portability, and/or increasing privacy and control of data_". So, by this definition, cryptocurrencies and blockchains _aren't_ inherently part of web3, though they might be used _in_ a web3 system.
[^2]: In contrast to most cryptocurrency-forward systems, which seem intent on the commodification of, and insertion of artificial scarcity into, almost everything ([Eevee](https://twitter.com/eevee) had a _great_ tweet about this that I can't now find, elaborating that the reason she's so opposed to crypto/web3/NFTs is that they're all about introducing scarcity to a digital space, the one place where it makes _no_ sense to exist - these [two](https://twitter.com/eevee/status/1467829679369326594) [threads](https://twitter.com/eevee/status/1460357576906850306) aren't it, but echo the sentiment). I'm generalizing - profiteering web3 projects and abundance-minded crypto projects both probably exist - but these are the themes I've noticed.
[^3]: Necessary, but not sufficient - I'm sure there are plenty of _other_ project problems that I haven't considered or listed here.
[^4]: Itself a purely nonsense notion, as can be verified by speaking to _either_ any lawyer _or_ any mature coder. Either will tell you (once they stop laughing) that encoding all the complexities of legislation to be evaluated and executed automatically, in a guaranteed bug-free and forward-compatible way that anticipates all possible edge-cases and situations, is a fool's dream for any but the simplest cases.
[^5]: Disclaimer - I'm an employee of Amazon Music, though I haven't been part of any strategic discussions about use of or competition with NFT-based services. As always, my posts don't represent my employer and I'm writing as an individual.
[^6]: See [here](https://docseuss.medium.com/look-what-you-made-me-do-a-lot-of-people-have-asked-me-to-make-nft-games-and-i-wont-because-i-m-29c7cfdbbb79) for a more comprehensive discussion of why NFTs are particularly unsuitable to videogames.
[^7]: I'm currently reading and greatly enjoying [Exit, Voice, and Loyalty](https://en.wikipedia.org/wiki/Exit,_Voice,_and_Loyalty), which talks in-depth about this trade-off, and reaction to deterioration.
[^8]: Not all! Some of them shamelessly state that the underlying artwork is nothing but a groundless basis for speculation which makes no claim about ownership, and that the NFT itself is just a means for gambling on whether people will want to buy "_a thing that represents (in no meaningful way) the other thing_". I mean....fuck 'em, they're money-grabbing scam artists, but you have to at least respect[^9] the brazen honesty.
[^9]: You do not, in fact, have to respect them. This is a figure of speech. I didn't think I had to explain this, but I've previously had someone interpret this seriously, so now I don't take chances...
[^10]: Remember, if you are reading this, [you are not the average customer...](https://xkcd.com/2501/)
