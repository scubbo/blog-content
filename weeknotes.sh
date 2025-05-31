#!/bin/bash

cd blog
hugo new content/posts/weeknotes-$(date +%Y-%m-%d).md
cursor content/posts/weeknotes-$(date +%Y-%m-%d).md