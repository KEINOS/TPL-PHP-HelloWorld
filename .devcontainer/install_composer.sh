#!/bin/sh

echo '========================================================================'
echo ' Installer of PHP Composer for VSCode'
echo '========================================================================'

echo '- Downloading installer of composer ...'
EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    echo >&2 '❌  ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet --install-dir=$(dirname $(which php)) --filename=composer &&
    composer --version &&
    composer diagnose &&
    rm composer-setup.php &&
    echo '✅  MOVED: composer.phar successfully moved to ENV PATH.'
