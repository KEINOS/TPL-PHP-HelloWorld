FROM php:5-cli-alpine

USER root

COPY ./src /app/src
COPY ./tests /app/tests
COPY ./composer.json /app/

WORKDIR /app
RUN apk --no-cache --update add \
        bash \
        git \
    && \
    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"; \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"; \
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"; \
    [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ] && { >&2 echo 'ERROR: Invalid installer signature'; exit 1; }; \
    php composer-setup.php --quiet --install-dir=$(dirname $(which php)) --filename=composer && \
    composer --version && \
    rm composer-setup.php && \
    composer global require phpunit/phpunit && \
    composer install --ignore-platform-reqs

ENTRYPOINT ["/bin/sh", "/app/tests/.testcontainer/entrypoint.php5.sh"]
