#!/bin/bash

# Usage:
# <script> -path <path> [-noGit]
#  * <path>, if present, should point to the path to Hugo root
#  * -noGit will disable git operation

set -e

# https://stackoverflow.com/a/52156612/1040915
declare -A flags
declare -A booleans
args=()

while [ "$1" ];
do
    arg=$1
    if [ "${1:0:1}" == "-" ]
    then
      shift
      rev=$(echo "$arg" | rev)
      if [ -z "$1" ] || [ "${1:0:1}" == "-" ] || [ "${rev:0:1}" == ":" ]
      then
        bool=$(echo ${arg:1} | sed s/://g)
        booleans[$bool]=true
        # echo \"$bool\" is boolean
      else
        value=$1
        flags[${arg:1}]=$value
        shift
        # echo \"$arg\" is flag with value \"$value\"
      fi
    else
      args+=("$arg")
      shift
      # echo \"$arg\" is an arg
    fi
done

if [ -z ${flags["path"]} ]; then
  path="blog";
else
  path=${flags["path"]};
fi

# https://stackoverflow.com/a/56841359/1040915
if [[ -z "${booleans['noGit']:-}" ]]; then
  # This assumes that the blog content is within the Git repo which contains the script location.
  # https://unix.stackexchange.com/a/155077/30828
  if [ -n "$(git status --porcelain)" ]; then
    echo "Working directory not clean - aborting";
    exit
  fi

  git push
fi

HUGO_ENV=production
hugo --quiet --source $path

cp -r $path/public ./blogContent
docker build -t scubbo/blog_nginx . -f-<<EOF
FROM nginxinc/nginx-unprivileged
COPY blogContent /usr/share/nginx/html
EOF

if [[ $(docker ps --filter "name=blog_nginx" | wc -l) -lt 2 ]]; then
  echo "No currently running blog"
else
  docker kill blog_nginx
  docker rm blog_nginx
fi

docker run --name blog_nginx -p 8108:8080 -d scubbo/blog_nginx
# TODO - call Cloudflare's CDN API to explicitly purge cache on the index page
# TODO - (more of a stretch) and parse the `git push` output to purge cache on updated pages, too
# TODO - do the "docker kill and restart" more idiomatically - there must be a "proper" way to do it!

rm -rf blogContent

