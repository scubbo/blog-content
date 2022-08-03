---
title: "Tracking Info"
type: "page"
extraHeadContent:
- <link rel="stylesheet" type="text/css" href="/css/plausible-exclusion.css">
- <link rel="stylesheet" type="text/css" href="/css/plausible-exclusion-override.css">
---
{{< rawhtml >}}
<!-- copied from https://plausible.io/docs/exclusion-examples/exclude.html via https://plausible.io/docs/excluding-localstorage#allow-anyone-on-your-site-to-exclude-themselves -->
<div class="container text-center mt-24" style="background: lightgrey; border-radius: 15px; padding: 20px; margin-top:  10px; margin-bottom: 10px">
    <h1 class="text-5xl font-black dark:text-gray-100">Plausible Exclude</h1>
    <div class="my-4 text-xl dark:text-gray-100">Click the button below to toggle your exclusion in analytics for this site</div>
    <div class="my-4 text-xl dark:text-gray-100">You currently <span class="dark:text-red-400 text-red-600 font-bold" id="plausible_not">are not</span><span class="dark:text-green-400 text-green-600 font-bold hidden" id="plausible_yes">are</span> excluding your visits.</div>
    <a class="py-2 px-4 bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-500 focus:ring-offset-indigo-200 text-white w-full transition ease-in duration-200 text-center text-base font-semibold shadow-md focus:outline-none focus:ring-2 focus:ring-offset-2 rounded-lg" id="plausible_button" href="javascript:toggleExclusion()">Exclude my visits</a>
</div>

<script>
    window.addEventListener('load', function (e) {
        var exclusionState = window.localStorage.plausible_ignore == "true"

        if (exclusionState) {
            document.getElementById("plausible_not").classList.add('hidden')
            document.getElementById("plausible_yes").classList.remove('hidden')
            document.getElementById("plausible_button").innerHTML = 'Stop excluding my visits'
        } else {
            document.getElementById("plausible_yes").classList.add('hidden')
            document.getElementById("plausible_not").classList.remove('hidden')
            document.getElementById("plausible_button").innerHTML = 'Exclude my visits'
        }
    });

    function toggleExclusion(e) {
        var exclusionState = window.localStorage.plausible_ignore == "true"

        if (exclusionState) {
            delete window.localStorage.plausible_ignore
            document.getElementById("plausible_yes").classList.add('hidden')
            document.getElementById("plausible_not").classList.remove('hidden')
            document.getElementById("plausible_button").innerHTML = 'Exclude my visits'
        } else {
            window.localStorage.plausible_ignore = "true"
            document.getElementById("plausible_not").classList.add('hidden')
            document.getElementById("plausible_yes").classList.remove('hidden')
            document.getElementById("plausible_button").innerHTML = 'Stop excluding my visits'
        }
    }
</script>
<!-- End copy -->
{{< /rawhtml >}}

## More info

This site uses a self-hosted [Plausible](https://plausible.io/) instance to track page hits. All data resides on my own server, and will never be given, sold, or otherwise distributed to third-parties. I will never use your data to market to you. Plausible was chosen because of its focus on [privacy](https://plausible.io/privacy-focused-web-analytics), anti-capitalism ("_We’re not interested in raising funds or taking investment. We choose the subscription business model rather than surveillance capitalism. We’re operating a sustainable project funded solely by the fees that our subscribers pay us. And we donate 5% of our revenue._"), and environmentalism ("_A site with 10,000 monthly visitors can save 4.5 kg of CO2 emissions per year by switching._").

Nevertheless, I recognize and applaud that some people do not want to be tracked at all, no matter how small-scale and personal the tracking. The tool above lets you opt yourself out of all tracking.

You can also use [standard AdBlockers](https://plausible.io/docs/excluding) to block Plausible - the domain name to block is `tracking.scubbo.org`.