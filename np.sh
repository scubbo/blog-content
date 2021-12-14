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
if [ -n "$EDITOR" ]; then
  $EDITOR $outputLocation
else
  echo "No default editor set - falling back to Sublime"
  # I expect this is only ever gonna be used by me anyway, so
  # I might as well set my own preference as the default :P
  subl $outputLocation
fi

popd > /dev/null
