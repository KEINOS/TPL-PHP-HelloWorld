#!/bin/bash

# =============================================================================
#  Functions
# =============================================================================

function echoHR(){
    # Draw Horizontal Line
    printf '%*s\n' "${SCREEN_WIDTH}" '' | tr ' ' ${1-=}
}

function echoInfoVersions () {
    echo '-' $(php --version | head -1)
    echo '-' $(composer --version)
}

function echoMsg () {
    echoHR '-'
    echo "  ${1}"
    echoHR '-'
}

function echoTitle () {
    echo
    echoHR
    echo "  ${1}"
    echoHR
}

function getPathParent () {
    echo "$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")"
}

function getPathScript () {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

function isInsideContainer () {
    [ -f /.dockerenv ] && return 0 || return 1
}

# =============================================================================
#  RUN Tests on local (Recall this script via Docker)
# =============================================================================
! isInsideContainer && {
    # Move to script's parent directory.
    cd "$(getPathParent)"

    [ "${1}" = "build" ] && {
        echoMsg 'Rebuilding test container ...'
        docker-compose build --no-cache test || {
            echoMsg '❌  Fail to build test container.'
            exit 1
        }
    }
    echoMsg 'Calling test container ...'
    docker-compose run test
    result=$?

    echo '- Removing prune container and images ...'
    docker container prune -f 1>/dev/null
    docker image prune -f 1>/dev/null

    exit $result
}

# =============================================================================
#  RUN Tests on Container (Actual Tests)
# =============================================================================
# Move to script's parent directory.
cd "$(getPathParent)"

echoTitle 'Running tests on docker'

# -----------------------------------------------------------------------------
#  Setup
# -----------------------------------------------------------------------------

# Load Token for COVERALLS
[ -e ./tests/conf/COVERALLS.env ] && {
    source ./tests/conf/COVERALLS.env
    export COVERALLS_RUN_LOCALLY=$COVERALLS_RUN_LOCALLY
    export COVERALLS_REPO_TOKEN=$COVERALLS_REPO_TOKEN
}

# Set width
which tput 2>/dev/null 1>/dev/null && [ -n "${TERM}" ] && {
    SCREEN_WIDTH=$(tput cols);
} || {
    SCREEN_WIDTH=80;
}

all_tests_passed=0

# -----------------------------------------------------------------------------
#  Main
# -----------------------------------------------------------------------------

echoTitle 'Diagnose: composer'
composer diagnose
if [ $? -eq 0 ];
    then echoMsg '✅  Diagnose: passed'
    else {
        echoMsg '❌  Diagnose: failed'
        all_tests_passed=1
    }
fi

echoTitle 'TEST: PHPUnit'

echo '- Removing old reports ...'
rm -rf ./report/*
echo '- Running PHPUnit'
./vendor/bin/phpunit \
    --configuration ./tests/conf/phpunit.xml \
    --testdox \
    --no-interaction
if [ $? -eq 0 ];
    then echoMsg '✅  PHPUnit: passed';
    else {
        echoMsg '❌  PHPUnit: failed'
        all_tests_passed=1
    }
fi

echoTitle 'TEST: Code Coverage'
echo $COVERALLS_REPO_TOKEN
[ "${COVERALLS_REPO_TOKEN:+notfound}" ] && {
    ./vendor/bin/php-coveralls \
        --config=./tests/conf/coveralls.yml \
        --json_path=./report/coveralls-upload.json \
        --verbose \
        --dry-run \
        --no-interaction
    if [ $? -eq 0 ];
        then {
            echoMsg '✅  COVERALLS: finished'
        };
        else {
            php -v | grep Xdebug 1>/dev/null 2>/dev/null
            [ $? -eq 0 ] && {
                echoMsg '❌  COVERALLS: failed'
                all_tests_passed=1
            } || {
                echoMsg '🛑  COVERALLS: SKIP'
                echo '- Xdebug extension is not enabled.'
            }
        }
    fi
} || {
    echoMsg '🛑  COVERALLS: SKIP'
    echo '- Token not set for COVERALLS.'
}

echoTitle 'TEST: PHPStan'
./vendor/bin/phpstan analyse src --level=max
if [ $? -eq 0 ];
    then echoMsg '✅  PHPStan: passed';
    else {
        echoMsg '❌  PHPStan: failed'
        all_tests_passed=1
    }
fi

echoTitle 'TEST: PSalm w/fix issue'
./vendor/bin/psalm \
    --debug \
    --root ./src \
    --alter \
    --issues=all
if [ $? -eq 0 ];
    then echoMsg '✅  PSalm: passed';
    else {
        echoMsg '❌  PSalm: failed'
        all_tests_passed=1
    }
fi

echoTitle 'TEST: Phan'
./vendor/bin/phan --allow-polyfill-parser
if [ $? -eq 0 ];
    then echoMsg '✅  Phan: passed';
    else {
        echoMsg '❌  Phan: failed'
        all_tests_passed=1
    }
fi

if [ $all_tests_passed -eq 0 ];
    then echoTitle '✅  All tests passed.'
    else echoTitle '❌  Some tests failed.'
fi

exit $all_tests_passed
