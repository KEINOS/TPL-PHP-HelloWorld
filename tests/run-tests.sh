#!/bin/bash
# =============================================================================
#  Test script.
#
#  This file should be called via "composer test" command. See "scripts" in
#  "/composer.json".
#
#  - Basic Options
#    $ composer test           # Run unit test whether in local or docker.
#    $ composer test all       # Run all the test and analyzing.
#    $ composer test phpstan   # Run unit test and phpstan analyzing.
#
#    Test options can be in any order
#      $ composer test phpstan psalm local
#
#  - Advanced Options
#    $ composer test local     # Run unit test in local
#    $ composer test docker    # Run unit test in Docker.
#    $ composer test local all # Run all the test and analyzing.
#
#  - Available test, analyzer and other options
#      verbose
#      requirement
#      diagnose
#      phpcs
#      phpcbf ... This will fix the marked sniff violations of PHPCS.
#      phpunit
#      phpstan
#      psalm
#      psalter ... Run Psalter via Psalm with --alter option.
#      phan
#      coveralls
#      build  ... Use this option to rebuild Docker test container.
# =============================================================================

# -----------------------------------------------------------------------------
#  Functions
#
#  Notes:
#    - Constant variables that won't be changed are in "CAPITAL_SNAKE_CASES".
#    - Global variables that might be changed are in "lower_snake_cases".
#    - Function names are in "lowerCamelCases()".
#    - "getter" functions begins with "get" and must be used as:
#        foo=$(getMyValue)
# -----------------------------------------------------------------------------
function buildContainerTest() {
    echoTitle 'Rebuilding test container'

    isInsideContainer && {
        echoError '❌  Running inside container. Docker in docker not supported.'
        exit 1
    }

    isDockerAvailable || {
        echoError '❌  Docker not installed.'
        exit 1
    }

    echo '- Building container ...'
    docker-compose build --no-cache $NAME_SERVICE_TEST || {
        echoError '❌  Fail to build test container.'
        exit 1
    }
}

function echoAlert() {
    echoHR '-'
    echo "💡  ${1}"
    echoHR '-'
}

function echoError() {
    echo >&2 "${1}"
}
function echoErrorHR() {
    echoHR >&2 '-'
    echo >&2 "  ${1}"
    echoHR >&2 '-'
}

function echoFlagOptions() {
    echo 'requirement diagnose phpcs phpcbf phpunit phpstan psalm phan coveralls'
}

function echoHelpOption() {
    echo '- Available Option Flags:'
    echo "    $(echoFlagOptions) (To test all use: all)"
    echo "    (optional for auto fix) psalter phpcbf"
}

function echoHR() {
    # Draw Horizontal Line
    printf '%*s\n' "${SCREEN_WIDTH}" '' | tr ' ' ${1-=}
}

function echoInfoVersions() {
    echo '-' $(php --version | head -1)
    echo '-' $(composer --version)
}

function echoMsg() {
    echo
    echo "  ${1}"
    echoHR '-'
}

function echoTitle() {
    echo
    echoHR
    echo "  ${1}"
    echoHR
}

function getPathParent() {
    # Use this function by "x=$(getPathParent)"
    echo "$(dirname "$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)")"
}

function getPathScript() {
    # Use this function by "x=$(getPathScript)"
    echo "$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)"
}

function getWidthScreen() {
    # Use this function by "x=$(getWidthScreen)"
    SCREEN_WIDTH_DEFAULT=80
    $(tput cols 2>/dev/null 1>/dev/null) && {
        SCREEN_WIDTH=$(tput cols)
    }
    SCREEN_WIDTH=${SCREEN_WIDTH:-$SCREEN_WIDTH_DEFAULT}
    echo $SCREEN_WIDTH
}

function isComposerInstalled() {
    composer --version 2>/dev/null 1>/dev/null && {
        return 0
    }

    return 1
}

function isDockerAvailable() {
    docker version 2>/dev/null 1>/dev/null && {
        return 0
    }

    return 1
}

function isDockerInstalled() {
    which docker 2>/dev/null 1>/dev/null && {
        return 0
    }

    return 1
}

function isFlagSet() {
    option=$(tr '[A-Z]' '[a-z]' <<<"${1}")
    echo "${list_option_given}" | grep $option 2>/dev/null 1>/dev/null
    return $?
}

function isInsideContainer() {
    isInsideTravis && {
        echoAlert 'You are running inside TravisCI.'
        return 0
    }

    [ -f /.dockerenv ] && {
        echoAlert 'You are running inside Docker container.'
        return 0
    }

    return 1
}

function isInsideTravis() {
    echo $(cd ~/ && pwd) | grep travis 1>/dev/null 2>/dev/null && {
        return 0
    }

    return 1
}

function isInstalledPackage() {
    echo -n "- Package: ${1} ... "
    [ -f "./vendor/bin/${1}" ] && {
        ./vendor/bin/$1 --version 2>/dev/null 1>/dev/null && {
            echo 'installed'
            return 0
        }
    }

    echo 'NOT FOUND'
    return 1
}

function isRequirementsInstallable() {
    ! isComposerInstalled && {
        flag_installable_requirements=1
    }

    [ "${flag_installable_requirements:+defined}" ] && {
        return $flag_installable_requirements
    }

    [ "${1}" = "verbose" ] && {
        indent='    '
        result=$(composer install --dry-run 2>&1 3>&1)
        flag_installable_requirements=$?
        echo
        echo "${result}" |
            while read line; do
                echo "${indent}${line}"
            done
        echo
    } || {
        composer install --dry-run 2>/dev/null 1>/dev/null
        flag_installable_requirements=$?
    }

    return $flag_installable_requirements
}

function isRequirementsInstalled() {
    isInstalledPackage phpunit &&
        isInstalledPackage phan &&
        isInstalledPackage php-coveralls &&
        isInstalledPackage phpstan &&
        isInstalledPackage psalm.phar &&
        isInstalledPackage phpcs && {
        return 0
    }

    return 1
}

function isXdebugAvailable() {
    php --version | grep Xdebug 2>/dev/null 1>/dev/null && {
        return 0
    }

    return 1
}

function loadConfCoverall() {
    path_file_conf_coveralls='./tests/conf/COVERALLS.env'
    if [ -f "${path_file_conf_coveralls}" ]; then
        {
            # Load Token for COVERALLS
            source $path_file_conf_coveralls
            export COVERALLS_RUN_LOCALLY=$COVERALLS_RUN_LOCALLY
            export COVERALLS_REPO_TOKEN=$COVERALLS_REPO_TOKEN
        }
    else
        {
            echo '- Conf file not found at:' $path_file_conf_coveralls
        }
    fi
}

function removeContainerPrune() {
    echo '- Removing prune container and images ...'
    docker container prune -f 1>/dev/null
    docker image prune -f 1>/dev/null
}

function runCoveralls() {
    echoTitle 'TEST: Code Coverage'
    # Skip if option not set
    ! isFlagSet 'coveralls' && {
        return 2
    }
    # Check Xdebug extension
    php -v | grep Xdebug 1>/dev/null 2>/dev/null
    [ $? -eq 0 ] || {
        echo '- Xdebug extension is not enabled. Skipping the test.'
        return 2
    }

    # Load token from conf files.
    loadConfCoverall

    # Check token for COVERALLS
    [ "${COVERALLS_REPO_TOKEN:+notfound}" ] || {
        echo '- Access token for COVERALLS not set. Skipping the test.'
        return 2
    }
    echo '- Token for COVERALLS found.'

    setOptionCoverallsDryRun

    echo '- Running COVERALLS'
    ./vendor/bin/php-coveralls \
        --config=./tests/conf/coveralls.yml \
        --json_path=./report/coveralls-upload.json \
        --verbose \
        --no-interaction \
        $option_dry_run
    [ $? -eq 0 ] && return 0 || return 1
}

function runDiagnose() {
    echoTitle 'DIAGNOSE: composer'
    # Skip if option not set
    ! isFlagSet 'diagnose' && {
        return 2
    }
    composer diagnose
    [ $? -eq 0 ] && return 0 || return 1
}

function runPhan() {
    echoTitle 'TEST: Phan'
    # Skip if option not set
    ! isFlagSet 'phan' && {
        return 2
    }
    PHAN_DISABLE_XDEBUG_WARN=1 \
        ./vendor/bin/phan \
        --allow-polyfill-parser \
        --directory ./src
    [ $? -eq 0 ] && return 0 || return 1
}

function runPhpcbf() {
    echoTitle 'FIX: Fix the marked sniff violations'
    # Skip if option not set
    ! isFlagSet 'phpcbf' && {
        return 2
    }
    ./vendor/bin/phpcbf -v
    [ $? -eq 0 ] && return 0 || return 1
}

function runPHPCS() {
    echoTitle 'TEST: PHP Code Sniffer (Compliant with PSR2)'
    # Skip if option not set
    ! isFlagSet 'phpcs' && {
        return 2
    }
    ./vendor/bin/phpcs -v
    [ $? -eq 0 ] && return 0 || return 1
}

function runPHPStan() {
    echoTitle 'TEST: PHPStan'
    # Skip if option not set
    ! isFlagSet 'phpstan' && {
        return 2
    }
    ./vendor/bin/phpstan \
        analyse src --level=max
    [ $? -eq 0 ] && return 0 || return 1
}

function runPHPUnit() {
    echoTitle 'TEST: PHPUnit'
    # Skip if option not set
    ! isFlagSet 'phpunit' && {
        return 2
    }
    echo '- Removing old reports ...'
    rm -rf ./report/*
    isXdebugAvailable || {
        echoAlert 'Xdebug not found. Code coverage driver will NOT be available. Thus Code Coverage might fail.'
    }
    setOptionPHPUnitTestdox
    echo '- Running PHPUnit'
    ./vendor/bin/phpunit \
        --configuration ./tests/conf/phpunit.xml \
        $option_testdox
    [ $? -eq 0 ] && return 0 || return 1
}

function runPsalm() {
    # Skip if option not set
    ! isFlagSet 'psalm' && {
        return 2
    }

    # Psalm fails with relative paths so specify as absolute path
    path_dir_current=$(getPathScript)
    path_dir_parent=$(dirname "${path_dir_current}")
    path_file_conf_psalm="${path_dir_current}/conf/psalm.xml"

    title_temp='TEST: PSalm'
    # Set psalter option if specified
    use_alter=''
    isFlagSet 'psalter' && {
        use_alter='--alter --issues=all'
        title_temp="${title_temp} (w/ alter and issue=all option)"
    }
    echoTitle "${title_temp}"
    ./vendor/bin/psalm.phar \
        --config="${path_file_conf_psalm}" \
        --root="${path_dir_parent}" \
        --show-info=true \
        $use_alter
    [ $? -eq 0 ] && return 0 || return 1
}

function runRequirementCheck() {
    echoTitle 'CHECK: Requirement check for tests'

    # Skip if option not set
    ! isFlagSet 'require' && {
        return 2
    }

    isRequirementsInstalled || {
        echoErrorHR '❌  Missing: composer packages.'
        echo '- Required packages for testing missing. Run "composer install" to install them.'
        exit 1
    }

    echo 'Basic requirements of composer installed.'
    return 0
}

function runTest() {
    name_test=$1
    # Run test function given
    $2
    result=$?
    # Echo results
    [ $result -eq 0 ] && echoMsg "✅  ${name_test}: passed"
    [ $result -eq 1 ] && {
        echoErrorHR "❌  ${name_test}: failed"
        all_tests_passed=1
    }
    [ $result -eq 2 ] && echoMsg "🛑  ${name_test}: skipped"
}

function runTestsInContainer() {
    echo '- Calling test container ...'
    echoTitle 'Running Tests in Container'
    docker-compose run \
        -e SCREEN_WIDTH=$SCREEN_WIDTH \
        $NAME_SERVICE_TEST "${@}"
    [ $? -eq 0 ] && return 0 || return 1
}

function setFlagsTestAllUp() {
    list_option_given="${list_option_given} $(echoFlagOptions)"
}

function setOptionCoverallsDryRun() {
    export COVERALLS_RUN_LOCALLY=1
    # Set dry-run option by default
    option_dry_run='--dry-run'
    isInsideTravis && {
        echo '- Running inside Travis detected.'
        export TRAVIS=${TRAVIS:-true}
        export CI_NAME=${CI_NAME:-travis-ci}
        # Unset dry-run option
        option_dry_run=''
    }
}

function setOptionPHPUnitTestdox() {
    option_testdox=''
    [ ${mode_verbose} -eq 0 ] && {
        option_testdox='--testdox'
    }
}

# =============================================================================
#  Setup
# =============================================================================
# Name of service container in docker-compose.
#   See: ../docker-compose.yml
NAME_SERVICE_TEST='test'

# Set width
export SCREEN_WIDTH=$(getWidthScreen)

# Moving to script's parent directory.
cd "$(getPathParent)"

# Set all options/args given to this script in lower case
list_option_given=$(tr '[A-Z]' '[a-z]' <<<"$@")

# Set initial result flag
#   0    -> All tests passed
#   else -> Some tests failed
all_tests_passed=0

# -----------------------------------------------------------------------------
#  Flag Option Setting
# -----------------------------------------------------------------------------
isFlagSet 'build' && {
    buildContainerTest
    exit $?
}

! isFlagSet 'local' && ! isFlagSet 'docker' && {
    isDockerAvailable && {
        echoAlert '[Auto-detect]: Docker found'
        echo '- Test will be run on Docker'
        echo '- To specify use: local or docker'
        list_option_given="${list_option_given} docker"
    }
}

# Set default move
[ ${#} -eq 0 ] && {
    echoAlert '[NO option specified]: Running only PHPUnit'
    echoHelpOption
}

# =============================================================================
#  Call this script it self via Docker
# =============================================================================
isFlagSet 'docker' && {
    ! isInsideContainer && isDockerAvailable && {
        list_option_given=$(echo "${list_option_given}" | sed -e 's/docker/local/g')
        runTestsInContainer "${list_option_given}"
        result=$?

        removeContainerPrune
        exit $result
    }

    isInsideContainer && {
        echoAlert 'You are already running inside the container.'
        exit 1
    }

    ! isDockerAvailable && {
        echoErrorHR '❌  ERROR: Docker not installed'
        echo '- Please install Docker or use "composer test local" option to run the tests locally.'
        exit 1
    }
}

# =============================================================================
#  Main
#  Run the actual tests.
# =============================================================================
#  Requirement check (Exit if not)
! isRequirementsInstalled 2>/dev/null 1>/dev/null && {
    echoErrorHR '❌  ERROR: Requirements not installed'
    echoError '  - Please install the requirements for testing.'

    isDockerInstalled && {
        ! isDockerAvailable && {
            echoErrorHR '💡  Docker is installed but it is not available to use.'
            echoError '  - Docker engine might be down. Check if Docker is running.'
        } || {
            echoErrorHR '💡  Docker is installed and available.'
            echoError '  - Consider running without "local" option.'
        }
    }

    isComposerInstalled || {
        echoErrorHR '❌  Composer NOT installed.'
        echoError '  - You need Docker or PHP composer to run this tests.'
        exit 1
    }

    echoErrorHR '💡  Composer is installed.'
    echoError '  - Checking if requirements can be installed in local ... (This may take time)'
    isRequirementsInstallable verbose && {
        echoError '💡  Requirements can be installed.'
        echoError '  - Run the below command to install your requirements in local.'
        echoError '    $ composer install'
    }

    echoError '  ❌  Composer packages can not be installed. See the above messages.'
    exit 1
}

# Update autoload
echoAlert 'Dumping composer autoload files'
composer dump-autoload

# Set minimum test
list_option_given="${list_option_given} phpunit"

# Set verbose mode flag
#   0    -> yes
#   else -> no
mode_verbose=1
isFlagSet 'verbose' && {
    mode_verbose=0
} || {
    echoAlert 'For detailed output use option: verbose'
}

# Set all the flags up, if "all" option is specified
isFlagSet 'all' && {
    echoAlert '[Full option specified]: Running all tests'
    setFlagsTestAllUp #Up all the test flags
}

# Run tests
runTest 'Check Requirements' runRequirementCheck
runTest 'Diagnose' runDiagnose
runTest 'PHPCBF' runPhpcbf
runTest 'PHPCS' runPHPCS
runTest 'PHPUnit' runPHPUnit
runTest 'PHPStan' runPHPStan
runTest 'Psalm' runPsalm
runTest 'Phan' runPhan
runTest 'Coveralls' runCoveralls

if [ $all_tests_passed -eq 0 ]; then
    echoTitle '✅  All tests passed.'
else
    echoTitle >&2 '❌  Some tests failed.'
fi

exit $all_tests_passed
