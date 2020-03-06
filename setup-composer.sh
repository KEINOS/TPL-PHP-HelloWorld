#!/bin/sh

# =============================================================================
#  Functions
# =============================================================================
function echoHR(){
    # Draw Horizontal Line
    printf '%*s\n' "${SCREEN_WIDTH}" '' | tr ' ' ${1-=}
}

function echoMsg () {
    echo "- ${1}"
}

function echoSubTitle () {
    echoHR '-'
    echo "■  $1"
    echoHR '-'
}

function echoTitle () {
    echo
    echoHR
    echo "  ${1}"
    echoHR
}

function isModeDev () {
    [ "${1}" = "--dev" ] && return 0 || return 1
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

# =============================================================================
#  Main
# =============================================================================

echoTitle 'Install & Setup PHP Composer'

echoSubTitle 'NOTE'
isModeDev $1 && {
    echo 'Option "--dev" detected. Dev dependencies will be installed.'
} || {
    echo 'No dev dependencies will be installed. To install them, use "--dev" option.'
}

echoSubTitle 'CHECK: PHP bin'
which php 1>/dev/null
[ $? -ne 0 ] && {
    echoMsg 'ERROR: No PHP found. PHP must be installed.'
    exit 1
}
echoMsg "💡  $(php -v)"

echoSubTitle 'CHECK: Composer bin'
which composer 1>/dev/null
[ $? -ne 0 ] && {
    echo '- Composer not found.'
    echoTitle 'Installing composer.'

    source ./.devcontainer/install_composer.sh
}
echoMsg "💡  $(composer --version)"

echoSubTitle 'DIAGNOSE: Diagnosing composer'
composer diagnose || {
    echoMsg '❌ ERROR: Composer diagnose failed.'
    exit 1
}
echoMsg '✅ Composer diagnose test passed.'

echoSubTitle 'VALIDATION: composer.yml'
[ -e ./composer.json ] || {
    echoMsg '💡  EXIT: ".composer.yml" not found.'
    exit
}
echoMsg '💡  composer.json found. Validating ...'
composer validate || {
    echoMsg '❌ ERROR: Invalid composer.json format.'
    exit 1
}
echoMsg '✅ Valid composer format!'

echoSubTitle 'Installing dependencies'
isModeDev $1 && {
    composer install --no-interaction && \
    ln -s ../psalm/phar/psalm.phar ./vendor/bin/psalm && \
    ls -la ./vendor/bin && \
    ls -l ./vendor/composer/../../ && \
    ./vendor/bin/psalm --init
    result=$?
} || {
    composer install --no-dev --no-interaction
    result=$?
}
[ $result -ne 0 ] && {
    echoMsg '❌ ERROR: Fail to install dependencies.'
    exit 1
}
echoMsg '✅ Composer packages installed!'
