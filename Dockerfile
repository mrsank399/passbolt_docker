FROM php:7-fpm-alpine3.7

LABEL MAINTAINER diego@passbolt.com

ENV PASSBOLT_VERSION 1.6.5
ENV PASSBOLT_URL https://github.com/passbolt/passbolt_api/archive/v${PASSBOLT_VERSION}.tar.gz

ARG PHP_EXTENSIONS="gd \
      intl \
      pdo_mysql \
      xsl"

ARG PHP_GNUPG_BUILD_DEPS="php7-dev \
      make \
      gcc \
      g++ \
      libc-dev \
      pkgconfig \
      re2c \
      gpgme-dev \
      autoconf \
      zlib-dev \
      file"

RUN apk add --no-cache $PHP_GNUPG_BUILD_DEPS \
      nginx \
      gpgme \
      gnupg1 \
      mysql-client \
      libpng-dev \
      icu-dev \
      libxslt-dev \
      libmcrypt-dev \
      supervisor \
    && pecl install gnupg redis mcrypt-snapshot \
    && docker-php-ext-install -j4 $PHP_EXTENSIONS \
    && docker-php-ext-enable $PHP_EXTENSIONS gnupg redis mcrypt \
    && apk del $PHP_GNUPG_BUILD_DEPS \
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

COPY src/passbolt_api/ /var/www/passbolt/

#    && curl -sSL $PASSBOLT_URL | tar zxf - -C /var/www/passbolt --strip-components 1 \
RUN cd /var/www/passbolt \
    && composer global require hirak/prestissimo \
    && composer install \
    && chown -R nginx:nginx /var/www/passbolt \
    && chmod -R o-w /var/www/passbolt \
    && chmod -R +w /var/www/passbolt/tmp \
    && chmod -R +w /var/www/passbolt/webroot/img/public

COPY conf/passbolt.conf /etc/nginx/conf.d/default.conf
COPY conf/supervisord.conf /etc/supervisord.conf
COPY bin/docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 80 443

CMD ["/docker-entrypoint.sh"]
