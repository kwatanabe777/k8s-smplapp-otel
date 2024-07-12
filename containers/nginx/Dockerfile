FROM nginx:1.27.0-alpine-otel

##### configuration for non-root user boot (for rewriting by entrypoint)
#COPY ./conf.d/default.conf /etc/nginx/conf.d/default.conf
RUN chgrp nginx -R /etc/nginx/conf.d && chmod g+w -R /etc/nginx/conf.d
COPY  ./containers/nginx/conf /etc/nginx/

# nginx.conf
#  don't exec setuid
#  & change worker_connections
#  & load opentelemetry module
RUN sed -i 's/user  nginx;/#user  nginx;/' /etc/nginx/nginx.conf \
    && sed -i 's/    worker_connections  1024;/    worker_connections  2048;/' /etc/nginx/nginx.conf \
    && sed -i 's/    keepalive_timeout  65;/    keepalive_timeout  65;/' /etc/nginx/nginx.conf \
    && sed -i -e '1i load_module modules/ngx_otel_module.so;' /etc/nginx/nginx.conf

# permission adjustment
RUN mkdir -p /var/www/public \
    && chmod -R a+rx /var/www/public \
    && chown -R nginx:nginx /var/cache/nginx \
    && touch /var/run/nginx.pid && chown -R nginx:nginx /var/run/nginx.pid

# copy sources
COPY ./webapp/public /var/www/public

# expose volumes
#  for socket sharing
VOLUME ["/var/run/php-fpm"]

EXPOSE 8080

USER nginx

