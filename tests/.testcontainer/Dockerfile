# To build this container you need to call it from the parent directory.
#   See: ../docker-comose.dev.yml
ARG NAME_IMAGE=php:cli-alpine
ARG COVERALLS_RUN_LOCALLY=1
ARG COVERALLS_REPO_TOKEN

FROM ${NAME_IMAGE}

USER root

COPY ./src /app/src
COPY ./tests /app/tests
COPY ./.devcontainer /app/.devcontainer
COPY ./*.json /app/

ENV COVERALLS_RUN_LOCALLY=$COVERALLS_RUN_LOCALLY COVERALLS_REPO_TOKEN=$COVERALLS_REPO_TOKEN
ENV COMPOSER='composer.dev.json'

WORKDIR /app
RUN apk --no-cache --update add \
        bash \
        git \
        autoconf \
        build-base \
        wget \
        zip unzip \
    && pecl install \
        xdebug \
        ast-1.0.6 \
    && docker-php-ext-enable \
        xdebug \
        ast \
    && /app/.devcontainer/setup_composer.sh --dev

ENTRYPOINT [ "/app/tests/run-tests.sh" ]
