# To build this container you need to call it from the parent directory.
# See ../docker-comose.yml
ARG NAME_IMAGE=php:cli-alpine
ARG COVERALLS_RUN_LOCALLY=1
ARG COVERALLS_REPO_TOKEN

FROM ${NAME_IMAGE}

USER root

COPY ./.devcontainer/install_composer.sh /app/.devcontainer/install_composer.sh
COPY ./setup-composer.sh /app/setup-composer.sh
COPY ./composer.json /app/composer.json
COPY ./src /app/src
COPY ./tests /app/tests

ENV COVERALLS_RUN_LOCALLY=$COVERALLS_RUN_LOCALLY COVERALLS_REPO_TOKEN=$COVERALLS_REPO_TOKEN
WORKDIR /app
RUN apk --no-cache add \
        bash \
        git \
        autoconf \
        build-base \
        wget \
        zip unzip \
        ncurses \
    && pecl install \
        xdebug \
        ast-1.0.6 \
    && docker-php-ext-enable \
        xdebug \
        ast \
    && /app/setup-composer.sh --dev

ENTRYPOINT [ "/app/tests/run-tests.sh" ]
