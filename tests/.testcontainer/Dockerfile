# To build this container you need to call it from the parent directory.
#   See: ../docker-comose.dev.yml
ARG NAME_IMAGE=php:8.0-cli-alpine
ARG COVERALLS_RUN_LOCALLY=1
ARG COVERALLS_REPO_TOKEN
ARG COMPOSER='composer.dev.json'

FROM ${NAME_IMAGE}

USER root

COPY ./src /app/src
COPY ./tests /app/tests
COPY ./.devcontainer /app/.devcontainer
COPY ./*.json /app/

ENV COVERALLS_RUN_LOCALLY=$COVERALLS_RUN_LOCALLY COVERALLS_REPO_TOKEN=$COVERALLS_REPO_TOKEN
ENV COMPOSER="${COMPOSER}"

WORKDIR /app
RUN apk --no-cache --update add \
        bash \
        git \
        autoconf \
        build-base \
        wget \
        zip unzip \
        re2c \
    && pecl channel-update pecl.php.net

RUN if php -r 'exit(version_compare(PHP_VERSION, "7.2.0", ">=") ? 0 : 1);'; then \
        yes | pecl install xdebug \
        && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.mode=coverage" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini; \
    else \
        yes | pecl install xdebug-2.9.8 \
        && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_autostart=on" >> /usr/local/etc/php/conf.d/xdebug.ini; \
    fi

RUN /app/.devcontainer/setup_composer.sh --dev

ENTRYPOINT [ "/app/tests/run-tests.sh" ]
