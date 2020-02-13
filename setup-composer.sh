#!/bin/sh

function install_bin_tests () {
    echo 'INSTALL: Installing composer packages for tests ...'
    composer bin phpstan require phpstan/phpstan phpstan/extension-installer
    composer bin psalm require vimeo/psalm
    composer bin phan require phan/phan
}

which php
[ $? -ne 0 ] && {
    echo 'ERROR: No PHP found. PHP must be installed.'
    exit 1
}
php -v

composer_newly_installed=1
which composer
[ $? -ne 0 ] && {
    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
    then
        >&2 echo 'ERROR: Invalid installer signature'
        rm composer-setup.php
        exit 1
    fi

    php composer-setup.php --quiet
    rm composer-setup.php
    mv ./composer.phar $(dirname $(which php))/composer && chmod +x $(dirname $(which php))/composer && \
    composer_newly_installed=0
}

composer --version

[ -d ./vendor ] && {
    composer validate || {
        echo 'ERROR: Invalid composer.json format.'
        exit 1
    }
    echo 'UPDATE: Updating composer ...'
    composer update
    install_bin_tests
}
composer update
[ $composer_newly_installed -eq 0 ] && {
    composer validate
    composer install --ignore-platform-reqs
    install_bin_tests
}
