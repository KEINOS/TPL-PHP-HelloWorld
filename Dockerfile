ARG NAME_IMAGE=php:cli-alpine
ARG COVERALLS_RUN_LOCALLY=1
ARG COVERALLS_REPO_TOKEN

FROM ${NAME_IMAGE}

COPY . /app
USER root
ENV COVERALLS_RUN_LOCALLY=$COVERALLS_RUN_LOCALLY COVERALLS_REPO_TOKEN=$COVERALLS_REPO_TOKEN
WORKDIR /app
RUN apk --no-cache add \
        git \
        autoconf \
        build-base && \
    pecl install xdebug && \
    docker-php-ext-enable xdebug && \
    /app/setup-composer.sh && \
    /app/run-tests.sh

ENTRYPOINT [ "/app/run-tests.sh" ]
