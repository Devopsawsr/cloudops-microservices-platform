FROM nginx:1.30.6-alpine3.24

# Keep Alpine packages at their latest patched versions within this base release.
RUN apk upgrade --no-cache

COPY services/web/public /usr/share/nginx/html
COPY services/web/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
