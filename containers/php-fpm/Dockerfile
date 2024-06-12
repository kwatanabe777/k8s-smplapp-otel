FROM php:8.3.7-fpm-alpine3.19

##### build args
ARG BUILD_OTEL
ARG BUILD_GRPC
ARG BUILD_PROTOBUF
##### environment
ENV BUILD_OTEL=${BUILD_OTEL}
ENV BUILD_GRPC=${BUILD_GRPC}
ENV BUILD_PROTOBUF=${BUILD_PROTOBUF}

ENV TZ Asia/Tokyo
# php composer
#ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_NO_INTERACTION 1

#### labels
LABEL BUILD_OTEL=${BUILD_OTEL} \
      BUILD_GRPC=${BUILD_GRPC} \
      BUILD_PROTOBUF=${BUILD_PROTOBUF}

##### install essential packages
#  (unzip is needed for preserving directory permissions on alpine(by composer))
#  (because busybox unzip does not preserve directory permissions, set to 777)
RUN sed -i 's/umask 022/umask 002/g' /etc/profile \
    && apk add --no-cache msmtp perl curl procps shadow unzip libpq icu libzip
##### add user for development(source code owner)
RUN addgroup -g 1000 devgrp && adduser -D -u 1000 -G devgrp devusr \
    && addgroup -S nginx && adduser -S nginx -G nginx && usermod -G 1000 nginx


##### install build pkgs & php extensions & composer
# (binutils for strip / linux-headers for xdebug)
RUN apk add --no-cache --virtual \
    .build-deps libpq-dev icu-dev icu-libs zlib-dev libzip-dev autoconf g++ make binutils curl-dev linux-headers \
    && docker-php-ext-install -j$(nproc) \
    pgsql \
    pdo_pgsql \
    intl \
    opcache \
    bcmath \
    zip \
    curl \
    && strip --strip-all /usr/local/lib/php/extensions/*/*.so \
    && MAKEFLAGS="-j $(nproc)" pecl install xdebug && docker-php-ext-enable xdebug \
       && strip --strip-all /usr/local/lib/php/extensions/*/xdebug.so \
    && echo "otel_enabled:${BUILD_OTEL}";if [ ${BUILD_OTEL} -eq 1 ]; then \
         MAKEFLAGS="-j $(nproc)" pecl install opentelemetry && docker-php-ext-enable opentelemetry \
           && strip --strip-all /usr/local/lib/php/extensions/*/opentelemetry.so; \
       fi \
    && echo "grpc_enabled:${BUILD_GRPC}";if [ ${BUILD_GRPC} -eq 1 ]; then \
         MAKEFLAGS="-j $(nproc)" pecl install grpc && docker-php-ext-enable grpc \
           && strip --strip-all /usr/local/lib/php/extensions/*/grpc.so; \
       fi \
    && echo "protobuf_enabled:${BUILD_PROTOBUF}";if [ ${BUILD_PROTOBUF} -eq 1 ]; then \
         MAKEFLAGS="-j $(nproc)" pecl install protobuf && docker-php-ext-enable protobuf \
           && strip --strip-all /usr/local/lib/php/extensions/*/protobuf.so; \
       fi \
    && apk del .build-deps && rm -rf /usr/src/php* && rm -rf /tmp/pear \
    && curl -L https://getcomposer.org/composer-stable.phar -o /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer

# setup unix domain socket & profiles dir
RUN mkdir /var/run/php-fpm \
    && chown nginx:nginx /var/run/php-fpm \
    && mkdir /tmp/xdebug \
    && chown devusr:devgrp /tmp/xdebug
# volume exposure
VOLUME ["/var/run/php-fpm"]
VOLUME ["/tmp/xdebug"]

##### php configurations
COPY ./containers/php-fpm/conf /usr/local/etc/
RUN find /usr/local/etc/php -type d -exec chown nginx:nginx {} \; \
    && chown nginx:nginx /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && ln -s /usr/local/etc/php/php.ini-producion /usr/local/etc/php/php.ini \
    && chown nginx:nginx /usr/local/etc/php-fpm.d/


##### apps setup
WORKDIR /var/www/webapp
# copy soruce
COPY ./webapp ./

# Reset app & install by composer
RUN chown -R devusr:devgrp . \
    && find . -type d -exec chmod 6775 -R {} \; \
    && find . -type f -exec chmod 664 -R {} \; \
    && rm -rf storage/logs/* \
    && : "##### install composer pkgs and framework deps operations" \
    && : "#####   & permisions for local dev" \
    && sh -c 'umask 0002; \
    if [ -e composer.json ]; then \
      composer install ; \
      if [ -e artisan ]; then \
        php artisan cache:clear && \
        php artisan config:clear && \
        php artisan route:clear && \
        php artisan route:cache && \
        php artisan view:clear && \
        php artisan view:cache && \
        chown -R nginx:nginx storage; \
	  elif [ -e spark ]; then \
        php spark cache:clear && \
        php spark logs:clear && \
        chown -R nginx:nginx writable; \
      fi; \
      chown -R devusr:devgrp . ; \
    fi'

# entrypoint creation
COPY ./containers/php-fpm/entrypoint.sh /

# entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# switch context user to nginx for security
USER nginx

