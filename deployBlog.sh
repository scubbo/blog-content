#!/bin/bash

set -e

# -p <path>
# $path should be the path to the root of the Hugo content
while getopts p: flag
do
    case "${flag}" in
        p) path=${OPTARG};;
    esac
done

if [ -z "$path" ]; then
  echo "Path not set"
  exit 1
fi

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

rm -rf blogContent

