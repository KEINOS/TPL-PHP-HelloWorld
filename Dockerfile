# This Dockerfile is used to deploy/release the app in Docker image.
# It uses the same latest PHP version in ".travis.yml".
FROM php:7.4.2-cli-alpine

COPY ./src /app/src
COPY ./composer.json /app/composer.json
COPY ./.devcontainer/install_composer.sh /app/install_composer.sh

# Install composer
WORKDIR /app
USER root
RUN \
    /app/setup-composer.sh && \
    composer install --no-dev --no-interaction

WORKDIR /app/src
USER root
ENTRYPOINT [ "php", "/app/src/Main.php" ]
