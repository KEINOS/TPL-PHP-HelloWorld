# To build this container you need to call it from the parent directory.
#   See: ../docker-comose.yml
ARG NAME_IMAGE=php:cli-alpine
ARG COVERALLS_RUN_LOCALLY=1
ARG COVERALLS_REPO_TOKEN

FROM ${NAME_IMAGE}

USER root

COPY . /app

ENV COVERALLS_RUN_LOCALLY=$COVERALLS_RUN_LOCALLY COVERALLS_REPO_TOKEN=$COVERALLS_REPO_TOKEN
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
    && /app/.init/setup-composer.sh --dev

ENTRYPOINT [ "/app/tests/run-tests.sh" ]
