FROM nginxinc/nginx-unprivileged
COPY blog/public /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/nginx_extra.conf
