#!/bin/bash
# =============================================================================
#  Test script.
#
#  This file should be called via "composer test" command. See "scripts" in
#  "/composer.json".
# =============================================================================

OPTIONS='requirement diagnose phpcs phpmd phpcbf phpunit phpstan psalm phan coveralls'

MSG_HELP=$(
    cat <<'HEREDOC'

- Basic Commands

    $ composer test
    $ composer bench
    $ composer compile

    test      ... Run the tests and/or analyzers in local or docker. For
                  detailed usage see the next section.
    bench     ... Run benchmarks in "./bench" dir.
    compile   ... Creates a Phar archive under "./bin" dir.

- Basic Test Command Usage

    composer test [option option ...]

    $ composer test
    $ composer test help

    $ composer test local
    $ composer test docker

    $ composer test phpmd
    $ composer test phpstan psalm
    $ composer test phpmd psalm local
    $ composer test all
    $ composer test all verbose

    Without an option, only unit test will be run.

- Available Options

    build        ... Re-builds the Docker container for testing.
    help         ... Shows this help.

    verbose      ... Displays test results in verbose mode.
    requirement  ... Check package requirement for developing
    diagnose     ... Diagnoses composer

    phan
    coveralls
    phpcs
    phpmd
    phpunit
    phpstan
    psalm

    phpcbf       ... Fix the marked sniff violations of PHPCS.
    psalter      ... Run Psalter to fix Psalm errors (Run psalm --alter).

HEREDOC
)

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
    docker-compose -f docker-compose.dev.yml build --no-cache $NAME_SERVICE_TEST || {
        echoError '❌  Fail to build test container.'
        exit 1
    }
}

function buildPhp5() {
    echo '- Building PHP5 test container image ...'
    name_image_php5=$(getNameImagePhp5)
    name_tag_php5=$(getNameTagPhp5)

    docker build \
        --network host \
        --no-cache \
        -t "${name_image_php5}:${name_tag_php5}" \
        --file ./tests/.testcontainer/Dockerfile.php5 \
        .
    [ $? -ne 0 ] && {
        echoError '❌  Failed to build image'
        exit 1
    }
    return 0
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
    echo "${OPTIONS}"
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

function getNameImagePhp5() {
    echo "php5_test"
}

function getNameTagPhp5() {
    echo "local"
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
    path_file_bin_installed_package="./vendor/bin/${1}"
    echo -n "    - Package: ${1} ... "
    [ -f $path_file_bin_installed_package ] || {
        echo "Package NOT FOUND at: ${path_file_bin_installed_package}"
        return 1
    }

    result=$(COMPOSER=composer.dev.json $path_file_bin_installed_package --version 2>&1) || {
        echo "Package NOT FOUND at: ${path_file_bin_installed_package} Msg: ${result}"
        return 1
    }

    echo 'installed'
    return 0
}

function isRequirementsInstallable() {
    flag_installable_requirements=1
    isComposerInstalled || {
        # composer is a must requirement
        echo 'Composer not installed. This is a must requirement.'
        return 1
    }

    [ "${1}" = "verbose" ] && {
        indent='    '
        result=$(COMPOSER=composer.dev.json composer install --dry-run 2>&1 3>&1)
        flag_installable_requirements=$?
        echo
        echo "${result}" |
            while read line; do
                echo "${indent}${line}"
            done
        echo
    } || {
        COMPOSER=composer.dev.json composer install --dry-run 2>/dev/null 1>/dev/null
        flag_installable_requirements=$?
    }

    return $flag_installable_requirements
}

function isRequirementsInstalled() {

    # To see which packages are not install run with 'verbose' option
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

function runPhp5() {
    isDockerAvailable || {
        echoError 'Docker is not available to run.'
        exit 1
    }

    isFlagSet 'build' && {
        buildPhp5
        exit $?
    }

    echoTitle 'TEST: Running tests on PHP5 via container'
    name_image_php5=$(getNameImagePhp5)
    name_tag_php5=$(getNameTagPhp5)
    docker image ls | grep $name_image_php5 | grep $name_tag_php5 1>/dev/null 2>/dev/null
    [ $? -ne 0 ] && {
        buildPhp5
    }

    echo '- Running container ...'
    docker run \
        --rm \
        -v $(pwd)/tests:/app/tests \
        -v $(pwd)/src:/app/src \
        -v $(pwd)/composer.json:/app/composer.json \
        "${name_image_php5}:${name_tag_php5}"
    exit $?
}

function runPhpcbf() {
    echoTitle 'FIX: Fix the marked sniff violations'
    # Skip if option not set
    ! isFlagSet 'phpcbf' && {
        return 2
    }
    ./vendor/bin/phpcbf --standard=./tests/conf/phpcs.xml -v
    [ $? -eq 0 ] && return 0 || return 1
}

function runPHPCS() {
    echoTitle 'TEST: PHP Code Sniffer (Compliant with PSR2)'
    # Skip if option not set
    ! isFlagSet 'phpcs' && {
        return 2
    }
    ./vendor/bin/phpcs --standard=./tests/conf/phpcs.xml -v
    [ $? -eq 0 ] && return 0 || return 1
}

function runPHPMD() {
    echoTitle 'TEST: PHPMD (Mess Detector)'
    # Skip if option not set
    ! isFlagSet 'phpmd' && {
        return 2
    }
    ./vendor/bin/phpmd ./src ansi ./tests/conf/phpmd.xml
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
    docker-compose --file docker-compose.dev.yml run \
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

function showHelp() {
    echoTitle 'Help for developing this package.'
    echo "${MSG_HELP}"
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

isFlagSet 'php5' && {
    isInsideContainer && {
        echoError '❌  You can not run "php5" option inside the container.'
        exit 1
    }
    runPhp5
    exit $?
}

isFlagSet 'help' && {
    showHelp
    exit $?
}

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

    isFlagSet 'verbose' && {
        isRequirementsInstalled
    }

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

    echoAlert '💡  Composer is installed.'
    echo '  - Checking if requirements can be installed in local ... (This may take time)'
    isRequirementsInstallable verbose && {
        echoAlert '💡  Requirements can be installed.'
        echo '  - Run the below command to install your requirements in local.'
        echo '    $ composer install'
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
runTest 'PHPMD' runPHPMD
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
