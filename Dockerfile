# This Dockerfile is used to deploy/release the app in Docker image.
# It uses the same latest PHP version in ".travis.yml".
FROM php:7.4.2-cli-alpine

USER root

COPY ./src /app/src
COPY ./composer.json /app/composer.json
COPY ./.devcontainer/install_composer.sh /install_composer.sh

WORKDIR /app

# Install composer and requirements
RUN /bin/sh /install_composer.sh && \
    composer install --no-dev --no-interaction

ENTRYPOINT [ "php", "/app/src/Main.php" ]
