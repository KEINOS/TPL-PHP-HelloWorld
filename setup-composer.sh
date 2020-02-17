#!/bin/sh

# =============================================================================
#  Functions
# =============================================================================
function echoHR(){
    # Draw Horizontal Line
    printf '%*s\n' "${SCREEN_WIDTH}" '' | tr ' ' ${1-=}
}

function echoMsg () {
    echoHR '-'
    echo ' ' $1
    echoHR '-'
}

function echoTitle () {
    echo
    echoHR
    echo ' ' $1
    echoHR
}

function isPHP8 () {
    php -v | grep PHP\ 8 1>/dev/null 2>/dev/null;
    return $?
}

# =============================================================================
#  Settings
# =============================================================================

cd $(cd $(dirname $0); pwd)

# Set width
if [ -n "${TERM}" ];
    then SCREEN_WIDTH=$(tput cols);
    else SCREEN_WIDTH=80;
fi

echoTitle 'CHECK: PHP'
which php 1>/dev/null
[ $? -ne 0 ] && {
    echoMsg 'ERROR: No PHP found. PHP must be installed.'
    exit 1
}
php -v

composer_newly_installed=1
echoTitle 'CHECK: Composer'
which composer 1>/dev/null
[ $? -ne 0 ] && {
    echo '- Composer not found.'
    echoTitle 'Installing composer.'

    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
    then
        >&2 echoMsg 'ERROR: Invalid installer signature'
        rm composer-setup.php
        exit 1
    fi

    php composer-setup.php --quiet
    rm composer-setup.php
    mv ./composer.phar $(dirname $(which php))/composer && chmod +x $(dirname $(which php))/composer && \
    composer_newly_installed=0
}
composer --version

echoTitle 'DIAGNOSE: Diagnosing composer'
composer diagnose || {
    echoMsg 'ERROR: Composer diagnose failed.'
    exit 1
}

[ -e ./composer.json ] && {
    echo '- composer.json found'
    echoMsg 'Validating composer.json ...'
    composer validate || {
        echoMsg 'ERROR: Invalid composer.json format.'
        exit 1
    }
}

echoTitle 'Installing dependencies'
composer install --no-interaction;

echoTitle 'Installing composer packages for tests ...'

echoMsg 'INSTALL: phpstan'
composer bin phpstan require phpstan/phpstan phpstan/extension-installer

echoMsg 'INSTALL: psalm'
composer bin psalm require vimeo/psalm
[ ! -e ./psalm.xml ] && {
    ./vendor/bin/psalm --init
}

echoMsg 'INSTALL: phan'
composer bin phan require phan/phan
[ ! -e ./.phan/config.php ] && {
    ./vendor/bin/phan --init
}
