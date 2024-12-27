---
title: "Upsert in Postgres"
date: 2024-12-26T16:35:42-08:00
tags:
  - tech-snippets

---
A _real_ quick blog post just to record a useful technique I just discovered that I'll want to have a record for in the future - if inserting into a Postgres table, so long as you're on `>9.5`, you can upsert-and-overwrite with the following syntax:
<!--more-->
```sql
INSERT INTO tablename (a, b, c) values (1, 2, 10)
ON CONFLICT (a) DO UPDATE SET a = EXCLUDED.a, b = EXCLUDED.b, c = EXCLUDED.c;
```

Ref [here](https://stackoverflow.com/a/30118648/1040915).
