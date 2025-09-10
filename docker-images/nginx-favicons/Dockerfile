# Multi-arch official image; supports amd64/arm64 out of the box
FROM nginx:alpine

# Remove the default site if you want a clean config
RUN rm -f /etc/nginx/conf.d/default.conf

# Config + static assets
COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY html/ /usr/share/nginx/html/

EXPOSE 80
HEALTHCHECK CMD wget -q -O - http://localhost/ || exit 1