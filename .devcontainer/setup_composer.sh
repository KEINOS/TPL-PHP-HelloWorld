#!/bin/sh
# This script installs the below:
#   - Composer: If not installed.
#   - Dependencies: Composer packages from "/composer.json".
#   - Dev-dependencies: If "--dev" option is specified in arg such like "./setup-composer.sh --dev"

# =============================================================================
#  Functions
# =============================================================================

echoHR() {
    # Draw Horizontal Line
    HR=$(printf '%*s' "$SCREEN_WIDTH" '' | tr ' ' "${1-=}")
    echo "$HR"
}

echoMsg() {
    echo "- ${1}"
}

echoSubTitle() {
    echoHR '-'
    echo "■  $1"
    echoHR '-'
}

echoTitle() {
    echo
    echoHR
    echo "  ${1}"
    echoHR
}

isModeDev() {
    [ "${1}" = "--dev" ] && return 0 || return 1
}

isPHP8() {
    php -r '(version_compare(PHP_VERSION, "8.0") >= 0) ? exit(0) : exit(1);'
    return $?
}

# =============================================================================
#  Settings
# =============================================================================

WORK_USER="${SUDO_USER:-$(whoami)}"

# Set current path
PATH_DIR_MOUNTED=$(pwd)
# Move to parent directory
PATH_DIR_SCRIPT=$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)
PATH_DIR_PARENT=$(dirname "$PATH_DIR_SCRIPT")
cd "$PATH_DIR_PARENT" || echo >&2 'Failed to move parent directory.'
echo "- Current working dir: $(pwd)"

# Set width
tput cols 2>/dev/null 1>/dev/null && {
    SCREEN_WIDTH=$(tput cols)
}
SCREEN_WIDTH=${SCREEN_WIDTH:-80}

# Set default Composer config and version
COMPOSER=${COMPOSER:-'composer.json'}
COMPOSER_VERSION=${COMPOSER_VERSION:-'1.10.19'}

# =============================================================================
#  Main
# =============================================================================

echoTitle 'Install & Setup PHP Composer'

echoSubTitle 'NOTE'
echo "- Who am I: $(whoami)"
echo "- Current path: ${PATH_DIR_MOUNTED}"
if isModeDev "${1}"; then
    echo '- Option "--dev" detected. Dev dependencies will be installed.'
else
    echo '- No dev dependencies will be installed. To install them, use "--dev" option.'
fi

echoSubTitle 'CHECK: PHP bin'
if ! which php 1>/dev/null; then
    echoMsg 'ERROR: No PHP found. PHP must be installed.'
    exit 1
fi
echoMsg "💡  $(php -v)"

echoSubTitle 'CHECK: Composer bin'
if isModeDev "${1}"; then
    echoMsg 'Removing old lock and vendor files of composer'
    rm -f ./composer.lock && echo 'Lock file removed ...'
    rm -rf ./vendor && echo 'Vendor dir removed ...'
fi
if ! composer 1>/dev/null; then
    echo '- Composer not found.'
    echoTitle 'Installing composer.'
    # Include installer and run
    # shellcheck source=./.devcontainer/install_composer.sh
    . ./.devcontainer/install_composer.sh
fi

if ! composer 1>/dev/null; then
    echoMsg 'ERROR: Failed to install composer.'
    exit 1
fi

# Downgrade PHP Composer from v2 to v1.
# This is needed to mantain the test package's compatibility. This might change in the future.
composer self-update "$COMPOSER_VERSION" || {
    echoMsg 'ERROR: Failed to downgrade composer.'
    exit 1
}

# Pre-create composer configuration directories
if ! test -f "${HOME}/.composer"; then
    mkdir -p "${HOME}/.composer"
fi
if ! test -f "/home/${WORK_USER}/.composer"; then
    mkdir -p "/home/${WORK_USER}/.composer"
fi

# Copy public keys of tags to both root and work user
if ! test -f "${HOME}/.composer/keys.tags.pub"; then
    echoMsg "💡  Composer public keys of tags for $(whoami) not fond"
    echo '- Downloding pub key of tags for composer ...'
    if ! wget https://composer.github.io/releases.pub -O "${HOME}/.composer/keys.tags.pub"; then
        echoMsg '❌ ERROR: Failed to download pub key.'
        exit 1
    fi
fi
if ! test -f "/home/${WORK_USER}/.composer/keys.tags.pub"; then
    echo "- Copying pub keys for composer from user $(whoami) .composer dir ..."
    if ! cp -f "${HOME}/.composer/keys.tags.pub" "/home/${WORK_USER}/.composer/keys.tags.pub"; then
        echoMsg '❌ ERROR: Failed to copy pub keys of tags.'
        exit 1
    fi
fi

# Copy public keys of dev to both root and work user
if ! test -f "${HOME}/.composer/keys.dev.pub"; then
    echoMsg "💡  Composer public keys of devs for $(whoami) not fond"
    echo '- Downloding pub key of dev for composer ...'
    if ! wget https://composer.github.io/snapshots.pub -O "${HOME}/.composer/keys.dev.pub"; then
        echoMsg '❌ ERROR: Failed to download pub key.'
        exit 1
    fi
fi
if ! test -f "/home/${WORK_USER}/.composer/keys.dev.pub"; then
    echoMsg "💡  Composer Public Keys of devs for ${WORK_USER} not fond"
    if ! cp -f "${HOME}/.composer/keys.dev.pub" "/home/${WORK_USER}/.composer/keys.dev.pub"; then
        echoMsg '❌ ERROR: Failed to copy pub keys of devs.'
        exit 1
    fi
fi

# Smoke test of composer
echoMsg "💡  $(composer --version)"

# Validating composer config file
echoSubTitle 'VALIDATION: composer.json'
[ -f ./composer.json ] || {
    echoMsg '❌ ERROR: "./composer.json" not found.'
    exit 1
}
echoMsg '💡  composer.json found. Validating ...'
composer validate ./composer.json || {
    echoMsg '❌ ERROR: Invalid composer.json format.'
    exit 1
}
echoMsg '✅ Valid composer format!'

# Diagnose composer
echoSubTitle 'DIAGNOSE: Diagnosing composer'
composer diagnose || {
    echoMsg '❌ ERROR: Composer diagnose failed.'
    exit 1
}
echoMsg '✅ Composer diagnose test passed.'

# Install Dependencies
echoSubTitle 'Installing dependencies'
if isModeDev "${1}"; then
    echoMsg "💡  Installing WITH dev packages (./${COMPOSER})"
    if isPHP8; then
        echo '- PHP8 detected. Ignoring platform reqs.'
        composer install -vv --ignore-platform-reqs --no-plugins
        result=$?
    else
        composer install -vv
        result=$?
    fi

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
else
    echoMsg '💡  Installing with NO dev packages'
    composer install --no-dev --no-interaction
    result=$?
fi

[ $result -ne 0 ] && {
    echoMsg '❌ ERROR: Fail to install dependencies.'
    exit 1
}
echoMsg '✅ Composer packages installed!'
