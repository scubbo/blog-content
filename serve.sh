#!/bin/bash

cd blog
# Most common extra arg to be passed is `-D`, to serve draft pages
hugo server --bind "0.0.0.0" $@
