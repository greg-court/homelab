FROM nginx:alpine@sha256:d67ea0d64d518b1bb04acde3b00f722ac3e9764b3209a9b0a98924ba35e4b779

# copy your nginx vhosts
COPY conf/default.conf /etc/nginx/conf.d/default.conf

# copy all static assets
COPY html /usr/share/nginx/html
