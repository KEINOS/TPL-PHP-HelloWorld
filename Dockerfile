ARG NAME_IMAGE=php:cli-alpine

FROM ${NAME_IMAGE}

COPY . /app
WORKDIR /app

USER root

RUN /app/run-tests.sh
