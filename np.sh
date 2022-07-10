#!/bin/bash

postName=$1
if [ -z $postName ]; then
  echo "Usage: np.sh <postName>"
  exit 1
fi

if [ "$#" -ne 1 ]; then
  echo "Expected 1 arguments but found $# - exiting"
  exit 1
fi

pushd blog > /dev/null

hugo new "posts/$postName.md"
outputLocation="content/posts/$postName.md"
# Use our own env variable to encode which editor
# should be used to edit blogposts. Setting $VISUAL
# to `subl` leads to it also being used by (among
# others) zsh's `edit-command-line`, which is
# undesired
if [ -n "$BLOG_EDITOR" ]; then
  $BLOG_EDITOR $outputLocation
elif [ -n "$VISUAL" ]; then
  $VISUAL $outputLocation
elif [ -n "$EDITOR" ]; then
  $EDITOR $outputLocation
else
  echo "No default editor set - falling back to Sublime"
  # I expect this is only ever gonna be used by me anyway, so
  # I might as well set my own preference as the default :P
  subl $outputLocation
fi

popd > /dev/null
