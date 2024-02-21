---
title: "Project Management and Async Functions"
date: 2024-02-20T21:32:49-08:00
tags:
  - homelab
  - programming-language-design
  - SDLC

---
In my greatest display yet of over-engineering and procrastinating-with-tooling, I've started self-hosting [OpenProject](https://www.openproject.org/) to track the tasks I want to carry out on my homelab (and their dependencies).
<!--more-->
![Screenshot of the OpenProject UI](/img/open-project-screenshot.png "Pictured - a very normal and rational and sensible thing to do")

Annoyingly, I didn't find out until _after_ installation that this system [lacks the main feature](https://community.openproject.org/topics/8612) that made me want to use a Project Management Solution™ over a basic old Bunch Of Text Files - dependency visualization and easy identification of unblocked tasks.

Fortunately, the system has an API (of course), and some time later I'd whipped up this little "beauty" to print out all the unblocked tasks (i.e. all those I could start work on immediately):

```python
#!/usr/bin/env python

import json
import os
import requests
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

PROJECT_ID=<id>
BASE_URL='http://url.to.my.openproject.installation'
API_KEY=os.environ['API_KEY']

def main():
  all_tasks = _req(f'api/v3/projects/{PROJECT_ID}/work_packages')['_embedded']['elements']
  unblocked_tasks = [
    {
      'id': elem['id'],
      'title': elem['subject'],
      'href': f'{BASE_URL}/work_packages/{elem["id"]}'
    } for elem in all_tasks
    if _task_is_unblocked(elem['id'])
  ]
  print(json.dumps(unblocked_tasks, indent=2))


def _task_is_unblocked(task_id: int) -> bool:
  relations_of_task = _req(f'api/v3/work_packages/{task_id}/relations')['_embedded']['elements']
  urls_to_blockers_of_task = [
    relation['_links']['from']['href']
    for relation in relations_of_task
    if relation['type'] == 'blocks'
    and relation['_links']['to']['href'].split('/')[4] == str(task_id)]
  return all([
    _req(url)['_embedded']['status']['isClosed']
    for url in urls_to_blockers_of_task])


def _req(path: str):
  return requests.get(f'{BASE_URL}/{path}', auth=('apikey', API_KEY), verify=False).json()

if __name__ == '__main__':
  main()
```

(Yes, I haven't installed TLS on my cluster yet. The task's right there in the screenshot, see!?)

This is, of course, inefficient as can possibly be\[citation needed\], as it doesn't use any parallelization for the _many_ network calls, nor any caching of often-referenced data. That's fine for now, as N is going to be real small for quite some time.

## Async functions as first-class language design

That actually gets me onto a different topic. For some years now I've enjoyed, shared, and referenced the [What Color Is Your Function?](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/) article, which (spoilers - seriously, if you are a software engineer, go read it, it's good!) points out the ways in which building-in `async` functions to a language make things really awkward when the rubber hits the road. For a long time I really resented this `async` annotation (which I first encountered in JavaScript, but I then found out it has spread to [Python](https://docs.python.org/3/library/asyncio-task.html), too), as to me it seemed like unnecessary extra overhead - why should I have to annotate _every_ function in my call-stack with `async` just because they called an asynchronous function at some point in the stack? Why, in the following snippet, does `top_level()` have to be `async`, when all it's doing is a synchronous operation on an blocking function?


```python
#!/usr/bin/env python
import asyncio

async def top_level():
  print(await mid_level() * 2)

async def mid_level():
  return await bottom_level() + 1

async def bottom_level():
  # Imagine that this called out to the network
  # or did some other actually-async operation
  return 1

if __name__ == '__main__':
  asyncio.run(top_level())
```

I recently read [this article](https://blainehansen.me/post/red-blue-functions-are-actually-good/) which made the interesting case that `async` should be thought of as a member of the Type System, surfacing information about the behaviour of the associated function:

> Colored functions reveal important realities of a program. Colored functions are essentially a type-system manifestation of program effects, all of which can have dramatic consequences on performance (unorganized io calls can be a latency disaster), security (io can touch the filesystem or the network and open security gaps), global state consistency (async functions often mutate global state, and the filesystem isn't the only example), and correctness/reliability (thrown exceptions are a program effect too, and a `Result` function is another kind of color). Colored functions don't "poison" your program, they inform you of the _reality that your program itself_ has been poisoned by these effects.

I...can see where they're coming from, I guess? According to this viewpoint, `mid_level` should still be declared as `async`, even though it `await`s the actually-asynchronous function, because...the "network-call-ingness" of `bottom_level` propagates up to `mid_level`? I hadn't thought of it that way, but I can see that that's true. My local definition of `mid_level` does nothing asynchronous, but asynchonicity is transitive.

Not gonna lie, though, I still find the experience of writing `async`-ified code really frustrating. I begin writing out my logic in terms of (normal) functions and their interactions, traversing down/through the logic tree from high-level concepts down to implementations of API calls - at which point I hit a network call, and then am forced to traverse back up the tree scattering `async`/`await`s everywhere where I previously had normal function declarations and invocations. Maybe - and I'm half-joking, half-serious here - I should just _start_ writing the program "as if" it was going to be asynchronous in the first place? I wonder what would change then.
