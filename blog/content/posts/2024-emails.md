---
title: "2024 Emails"
date: 2025-01-01T17:10:13-08:00
draft: true
extraHeadContent:
- <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.js" integrity="sha512-ZwR1/gSZM3ai6vCdI+LVF1zSq/5HznD3ZSTk7kajkaj4D292NLuduDCO1c/NT8Id+jE58KYLKT7hXnbtryGmMg==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
- <script src="https://cdn.jsdelivr.net/npm/moment@2.27.0"></script>
- <script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-moment@0.1.1"></script>
- <script src="/js/email-graph.js"></script>
tags:
  - dataviz
  - gtd
  - productivity

---
On a whim, I started tracking my email volume during my morning startup routine during 2024.
<!--more-->
Specifically, for each of my email accounts (gmail and proton), I recorded the number of unread emails I had at the start of the morning, and how many remained unread at the end of the routine. The _ideal_ would be for the latter number to [always be 0](https://clean.email/blog/productivity/what-is-zero-inbox). Practically speaking, I tended to aim for ensuring that I had one fewer unread email in each account than I'd ended the previous day with - acknowledging that, since I wouldn't be checking my email every day (life gets in the way!), there would be regular spikes.

Anyway, here's ~~wonderwall~~ the graph[^chart-js]:

{{< rawhtml >}}
<canvas id="graph_canvas"></canvas>
{{< /rawhtml >}}

And filtered views of just each account

{{< rawhtml >}}
<canvas id="gmail_graph_canvas"></canvas>
{{< /rawhtml >}}

{{< rawhtml >}}
<canvas id="proton_graph_canvas"></canvas>
{{< /rawhtml >}}

I'm not sure what conclusions to draw from this, other than:
* I didn't check my email very much (or, at least, didn't track my checking) during May and June (unsurprising, as this was the time I was dealing with my Mum's passing-away)
* I received a _lot_ of emails in early July (again - unsurprising. This was mostly syncing up with interaction with the solicitors, funeral home, etc.)
* I'm receiving more email on my Gmail Account than my Proton. Unsurprising once again, as I've had that account for decades (as opposed to a year or so for Protonmail) and am probably on way more mailing lists that I should probably unsubscribe from, as well as being the account associated with various accounts and ecommerce sites.

I can't think why anyone _would_ - but if you want to see the code that generated this, it's here:

```python
#!/usr/bin/env python3

import os
import pathlib

import yaml

counts = {}

def main():
  should_hide_gmail = os.environ.get('SHOULD_HIDE_GMAIL') == 'TRUE'
  if not should_hide_gmail:
    counts['gmail-start'] = []
    counts['gmail-end'] = []

  should_hide_proton = os.environ.get('SHOULD_HIDE_PROTON') == 'TRUE'
  if not should_hide_proton:
    counts['proton-start'] = []
    counts['proton-end'] = []

  d = pathlib.Path('/Users/scubbo/Dropbox/Obsidian/scubbo-vault/GTD/Daily TODOs')
  for f_path in d.iterdir():
    if f_path.is_dir():
      continue
    if not f_path.name.startswith('Todo - 2024'):
      continue
    with f_path.open('r') as f:
      date = f_path.name[7:-3]

      content = f.read()
      data_index = content.index('# Data')
      start_of_data_block = data_index+content[data_index:].index('```') + 3
      length_of_data_block = content[start_of_data_block:].index('```')
      data = yaml.safe_load(content[start_of_data_block:start_of_data_block+length_of_data_block])
      if not should_hide_gmail:
        if gs_count := data['gmail']['start-count']:
          counts['gmail-start'].append({'date': date, 'count': gs_count})
        if ge_count := data['gmail']['end-count']:
          counts['gmail-end'].append({'date': date, 'count': ge_count})
      if not should_hide_proton:
        if ps_count := data['protonmail']['start-count']:
          counts['proton-start'].append({'date': date, 'count': ps_count})
        if pe_count := data['protonmail']['end-count']:
          counts['proton-end'].append({'date': date, 'count': pe_count})

  print([{'label': key, 'data': sorted(value, key=lambda x: x['date'])} for key, value in counts.items()])

if __name__ == '__main__':
  main()
```

Output was piped to `pbcopy`, and then hard-coded into the JS that serves this page.

[^chart-js]: made with [Chart.js](https://www.chartjs.org/), which I'd already used in my [EDH ELO tracker](https://gitea.scubbo.org/scubbo/edh-elo).

<!--
Reminders of patterns you often forget:

Images:
![Alt-text](url "Caption")

Internal links:
[Link-text](\{\{< ref "/posts/name-of-post" >}})
(remove the slashes - this is so that the commented-out content will not prevent a built while editing)
-->