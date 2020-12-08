#!/bin/sh
# This script installs the below:
#   - Composer: If not installed.
#   - Dependencies: Composer packages from "/composer.json".
#   - Dev-dependencies: If "--dev" option is specified in arg such like "./setup-composer.sh --dev"

# =============================================================================
#  Functions
# =============================================================================
function echoHR() {
    # Draw Horizontal Line
    HR=$(printf '%*s' "${SCREEN_WIDTH}" '' | tr ' ' ${1-=})
    echo "$HR"
}

function echoMsg() {
    echo "- ${1}"
}

function echoSubTitle() {
    echoHR '-'
    echo "■  $1"
    echoHR '-'
}

function echoTitle() {
    echo
    echoHR
    echo "  ${1}"
    echoHR
}

function isModeDev() {
    [ "${1}" = "--dev" ] && return 0 || return 1
}

function isPHP8(){
    php -r '(version_compare(PHP_VERSION, "8.0") >= 0) ? exit(0) : exit(1);'
    return $?
}

# =============================================================================
#  Settings
# =============================================================================

# Set current path
PATH_DIR_MOUNTED=$(pwd)
# Move to parent directory
PATH_DIR_SCRIPT=$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)
PATH_DIR_PARENT=$(dirname "$PATH_DIR_SCRIPT")
cd "$PATH_DIR_PARENT"
echo "- Current working dir: $(pwd)"

# Set width
$(tput cols 2>/dev/null 1>/dev/null) && {
    SCREEN_WIDTH=$(tput cols)
}
SCREEN_WIDTH=${SCREEN_WIDTH:-80}

# =============================================================================
#  Main
# =============================================================================

echoTitle 'Install & Setup PHP Composer'

echoSubTitle 'NOTE'
echo
echo "- Current path: ${PATH_DIR_MOUNTED}"
isModeDev $1 && {
    echo '- Option "--dev" detected. Dev dependencies will be installed.'
} || {
    echo '- No dev dependencies will be installed. To install them, use "--dev" option.'
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

[ -f "~/.composer/keys.tags.pub" ] && [ -f "~/.composer/keys.dev.pub" ] || {
    echoMsg "💡  Composer Public Keys for $(whoami) not fond"
    echo '- Downloding pub keys for composer ...'
    mkdir -p ~/.composer
    wget https://composer.github.io/releases.pub -O ~/.composer/keys.tags.pub &&
        wget https://composer.github.io/snapshots.pub -O ~/.composer/keys.dev.pub || {
        echoMsg '❌ ERROR: Failed to download pub keys.'
        exit 1
    }
}

[ -f "/home/${SUDO_USER}/.composer/keys.tags.pub" ] && [ -f "/home/${SUDO_USER}/.composer/keys.dev.pub" ] || {
    echoMsg "💡  Composer Public Keys for ${SUDO_USER} not fond"
    echo "- Copying pub keys for composer from user $(whoami) .composer dir ..."
    mkdir -p "/home/${SUDO_USER}/.composer"
    cp -f ~/.composer/keys.tags.pub "/home/${SUDO_USER}/.composer/keys.tags.pub" &&
        cp -f ~/.composer/keys.dev.pub "/home/${SUDO_USER}/.composer/keys.dev.pub"
    [ "$?" -ne 0 ] && {
        echoMsg '❌ ERROR: Failed to copy pub keys.'
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

echoSubTitle 'VALIDATION: composer.json for production'
[ -f ./composer.json ] || {
    echoMsg '💡  EXIT: "./composer.json" not found.'
    exit 1
}
echoMsg '💡  composer.json found. Validating ...'
composer validate ./composer.json || {
    echoMsg '❌ ERROR: Invalid composer.json format.'
    exit 1
}
echoMsg '✅ Valid composer format!'

echoSubTitle 'VALIDATION: composer.dev.json for development'
[ -f ./composer.dev.json ] || {
    echoMsg '💡  EXIT: "./composer.dev.json" not found.'
    exit 1
}
echoMsg '💡  composer.dev.json found. Validating ...'
composer validate ./composer.dev.json || {
    echoMsg '❌ ERROR: Invalid composer.dev.json format.'
    exit 1
}
echoMsg '✅ Valid composer format!'

echoSubTitle 'Installing dependencies'
isModeDev $1 && {
    echoMsg 'Removing old lock and vendor files of composer'
    rm -f ./composer.lock && echo 'Lock file removed ...'
    rm -f ./composer.dev.lock && echo 'Lock file removed ...'
    rm -rf ./vendor && echo 'Vendor dir removed ...'
    echoMsg '💡  Installing WITH dev packages (./composer.dev.json)'
    isPHP8 && {
        echo '- PHP8 detected. Ignoring platform reqs.'
        COMPOSER='composer.dev.json' composer install -vv --ignore-platform-reqs
        result=$?
    } || {
        COMPOSER='composer.dev.json' composer install -vv
        result=$?
    }
    # some version of psalm forgets to create sym-link
    ! [ -f ./vendor/bin/psalm ] && {
        echoMsg 'Creating sym-link to: ./vendor/bin/psalm'
        ln -s ../psalm/phar/psalm.phar ./vendor/bin/psalm
    }
    # check psalm.xml exists
    ! [ -f ./tests/conf/psalm.xml ] && {
        echoMsg 'Creating psalm conf file to: ./test/conf/psalm.xml'
        ./vendor/bin/psalm --init source_dir="../../src" level=8 &&
            mv -f ./psalm.xml ./test/conf/psalm.xml
    }
}

! isModeDev $1 && {
    export COMPOSER='composer.json'
    echoMsg '💡  Installing with NO dev packages'
    composer install --no-dev --no-interaction
    result=$?
}

[ $result -ne 0 ] && {
    echoMsg '❌ ERROR: Fail to install dependencies.'
    exit 1
}
echoMsg '✅ Composer packages installed!'
