#!/bin/bash

# =============================================================================
#  Functions
# =============================================================================

function buildContainerTest () {
    echoTitle 'Rebuilding test container'
    isDockerAvailable || {
        echoMsg '❌  Docker not installed.'
        exit 1
    }

    echo '- Building container ...'
    docker-compose build --no-cache test || {
        echoMsg '❌  Fail to build test container.'
        exit 1
    }
}

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

function isDockerAvailable () {
    docker version 2>/dev/null 1>/dev/null && {
        return 0
    }

    return 1
}

function isInsideContainer () {
    isInsideTravis && {
        echoMsg '💡  You are running inside TravisCI.'
        return 0
    }

    [ -f /.dockerenv ] && {
        echoMsg '💡  You are running inside Docker container.'
        return 0
    }

    return 1
}

function isInsideTravis () {
    echo $(cd ~/ && pwd) | grep travis 1>/dev/null 2>/dev/null && {
        return 0
    }

    return 1
}

function isInstalledPakcage () {
    [ -f "./vendor/bin/${1}" ] &&{
        ./vendor/bin/$1 --version 2>/dev/null 1>/dev/null && {
            return 0
        }
    }

    return 1
}

function isInstalledRequirements () {
    isInstalledPakcage phpunit && \
    isInstalledPakcage phan && \
    isInstalledPakcage php-coveralls && \
    isInstalledPakcage phpstan && \
    isInstalledPakcage psalm && {
        return 0
    }

    return 1
}

function removeContainerPrune () {
    echo '- Removing prune container and images ...'
    docker container prune -f 1>/dev/null
    docker image prune -f 1>/dev/null
}

function runContainerTest () {
    echoMsg 'Calling test container ...'
    echoTitle 'Running Tests in Container'
    docker-compose run test

    return $?
}

# =============================================================================
#  Setup
# =============================================================================

# Set width
which tput 2>/dev/null 1>/dev/null && [ -n "${TERM}" ] && {
    SCREEN_WIDTH=$(tput cols);
} || {
    SCREEN_WIDTH=80;
}

all_tests_passed=0

# Moving to script's parent directory.
cd "$(getPathParent)"

# =============================================================================
#  RUN Tests on local (Recall this script via Docker)
# =============================================================================
[ "${1}" = "build" ] && {
    buildContainerTest
}

! [ "${1}" = "local" ] && ! isInsideContainer && {
    isInstalledRequirements && {
        echoMsg '💡  Requirements all installed in local'
        echo '- RECOMMEND: Use "composer test local" command for faster testresults.'
    }

    runContainerTest
    result=$?

    removeContainerPrune
    exit $result
}

# =============================================================================
#  RUN Tests on Container (Actual Tests)
# =============================================================================
# -----------------------------------------------------------------------------
#  Main
# -----------------------------------------------------------------------------

echoTitle 'Running tests'

isInstalledRequirements || {
    echoMsg '❌  Missing: composer packages.'
    echo '- Some packages are missing. Run "composer install"'
    exit 1
}
echo '- Basic requirements of composer installed.'

echoTitle 'DIAGNOSE: composer'
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
    --testdox
if [ $? -eq 0 ];
    then echoMsg '✅  PHPUnit: passed';
    else {
        echoMsg '❌  PHPUnit: failed'
        all_tests_passed=1
    }
fi

echoTitle 'TEST: PHPStan'
./vendor/bin/phpstan analyse src --level=max
if [ $? -eq 0 ];
    then echoMsg '✅  PHPStan: passed';
    else {
        echoMsg '❌  PHPStan: failed'
        all_tests_passed=1
    }
fi

echoTitle 'TEST: PSalm (w/ alter and issue=all option)'
./vendor/bin/psalm \
    --config=./tests/conf/psalm.xml \
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
PHAN_DISABLE_XDEBUG_WARN=1 \
./vendor/bin/phan \
    --allow-polyfill-parser \
    --directory ./src
if [ $? -eq 0 ];
    then echoMsg '✅  Phan: passed';
    else {
        echoMsg '❌  Phan: failed'
        all_tests_passed=1
    }
fi

echoTitle 'TEST: Code Coverage'
[ -f ./tests/conf/COVERALLS.env ] && {
    # Load Token for COVERALLS
    source ./tests/conf/COVERALLS.env
    export COVERALLS_RUN_LOCALLY=$COVERALLS_RUN_LOCALLY
    export COVERALLS_REPO_TOKEN=$COVERALLS_REPO_TOKEN
}
[ "${COVERALLS_REPO_TOKEN:+notfound}" ] && {
    echo '- Token for COVERALLS found.'

    export COVERALLS_RUN_LOCALLY=1
    option_dry_run='--dry-run'
    isInsideTravis && {
        echo '- Running inside Travis detected.'
        export TRAVIS=${TRAVIS:-true}
        export CI_NAME=${CI_NAME:-travis-ci}
        option_dry_run=
    }
    ./vendor/bin/php-coveralls \
        --config=./tests/conf/coveralls.yml \
        --json_path=./report/coveralls-upload.json \
        --verbose \
        $option_dry_run \
        --no-interaction
    if [ $? -eq 0 ];
        then {
            echoMsg '✅  COVERALLS: finished'
        };
        else {
            php -v | grep Xdebug 1>/dev/null 2>/dev/null
            [ $? -eq 0 ] && {
                echoMsg '❌  COVERALLS: failed'
                echo '- ENV'; env | sort
                echo '- Other variables'; (set -o posix ; set)
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

if [ $all_tests_passed -eq 0 ];
    then echoTitle '✅  All tests passed.'
    else echoTitle '❌  Some tests failed.'
fi

exit $all_tests_passed
