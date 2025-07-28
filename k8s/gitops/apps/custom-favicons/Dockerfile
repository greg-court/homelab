FROM nginx:alpine

# copy your nginx vhosts
COPY conf/default.conf /etc/nginx/conf.d/default.conf

# copy all static assets
COPY html /usr/share/nginx/html
