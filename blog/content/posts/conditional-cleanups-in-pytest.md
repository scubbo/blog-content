---
title: "Conditional Cleanups in Pytest"
date: 2024-04-28T16:55:37-07:00
tags:
  - python
  - testing

---
A helpful pattern in testing is to take some cleanup action _only_ if the test passes/fails. For instance, for a test which interacts with an on-filesystem database, the database should be deleted if the test passes, but it should stick around if the test fails so that the developer can examine it and debug.
<!--more-->
In JUnit, this is possible [via a `@Rule`](http://www.thinkcode.se/blog/2012/07/08/performing-an-action-when-a-test-fails), but as far as I can tell there's no pre-built equivalent in Python's `pytest`. I did find [this StackOverflow answer](https://stackoverflow.com/a/69283090/1040915) describing an approach using the [`pytest_runtest_makereport`](https://docs.pytest.org/en/latest/reference/reference.html#pytest.hookspec.pytest_runtest_makereport) hook, though the syntax appears to have changed since that answer. I put together an example implementation [here](https://gitea.scubbo.org/scubbo/pytest-conditional-cleanup-demo), which also adds the ability for fixtures _and_ tests to add "cleanup" actions to a stack, which will be executed in reverse order.
