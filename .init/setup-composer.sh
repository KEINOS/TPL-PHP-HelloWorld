#!/bin/sh
# This script installs the below:
#   - Composer: If not installed.
#   - Dependencies: Composer packages from "/composer.json".
#   - Dev-dependencies: If "--dev" option is specified in arg such like "./setup-composer.sh --dev"

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

# Move to parent directory
PATH_DIR_SCRIPT=$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)
PATH_DIR_PARENT=$(dirname "$PATH_DIR_SCRIPT")
cd "$PATH_DIR_PARENT"

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
[ -f ~/.composer/keys.tags.pub ] && [ -f ~/.composer/keys.dev.pub ] || {
    echoMsg '💡  Composer Public Keys not fond'
    echo '- Downloding pub keys for composer ...'
    mkdir -p ~/.composer
    wget https://composer.github.io/releases.pub -O ~/.composer/keys.tags.pub && \
    wget https://composer.github.io/snapshots.pub -O ~/.composer/keys.dev.pub || {
        echoMsg '❌ ERROR: Failed to download pub keys.'
        exit 1
    }
}
echoMsg "💡  $(composer --version)"

echoSubTitle 'DIAGNOSE: Diagnosing composer'
composer diagnose || {
    echoMsg '❌ ERROR: Composer diagnose failed.'
    exit 1
}
echoMsg '✅ Composer diagnose test passed.'

echoSubTitle 'VALIDATION: composer.yml'
[ -f ./composer.json ] || {
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
    echoMsg '💡  Installing WITH dev packages'
    composer install --no-interaction
    result=$?
    # some version of psalm forgets to create sym-link
    ! [ -f ./vendor/bin/psalm ] && {
        echoMsg 'Creating sym-link to: ./vendor/bin/psalm'
        ln -s ../psalm/phar/psalm.phar ./vendor/bin/psalm
    }
    # check psalm.xml exists
    ! [ -f ./tests/conf/psalm.xml ] && {
        echoMsg 'Creating psalm conf file to: ./test/conf/psalm.xml'
        ./vendor/bin/psalm --init source_dir="../../src" level=8 && \
        mv -f ./psalm.xml ./test/conf/psalm.xml
    }
}
! isModeDev $1 && {
    echoMsg '💡  Installing with NO dev packages'
    composer install --no-dev --no-interaction
    result=$?
}

[ $result -ne 0 ] && {
    echoMsg '❌ ERROR: Fail to install dependencies.'
    exit 1
}
echoMsg '✅ Composer packages installed!'
