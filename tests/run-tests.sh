#!/bin/sh
# =============================================================================
#  Test script.
#
#  This file should be:
#    1. Called via "composer test" command. See "scripts" in "/composer.json".
#    2. Compatible with POSIX/bourne shell and not bash. Use `shellcheck` cmd.
#       $ shellcheck -x -s sh ./tests/run-tests.sh
# =============================================================================

# Available options 'a la carte' for testing.
OPTIONS="\
 --requirement \
 --diagnose \
 --phpcs \
 --phpmd \
 --phpcbf \
 --phpunit \
 --phpstan \
 --psalm \
 --phan \
 --coveralls"

MSG_HELP=$(
    cat <<'HEREDOC'
- Basic Commands

    Syntax:
      composer [command]

    Commands:
      test       ... Run the tests and/or analyzers in local or docker. For
                     detailed usage see the next section.
      shellcheck ... Run static analysis of shell script(*.sh) files. Except
                     the "./vendor" directory.
      bench      ... Run benchmarks in "./bench" dir.
      compile    ... Creates a Phar archive under "./bin" dir using `box`.
                     (This command is unstable)

    Sample:
      $ composer test
      $ composer shellcheck
      $ composer bench
      $ composer compile

- Basic "test" Command Usage

    Syntax:
      composer test [help] [-- --option --option ...]

    Sample:
      $ composer test help ... Shows this help.

- Available "test" Command Options

    Syntax:
      composer test -- [--option --option ...]

    Note:
      - Append "--" before options.
      - PHPUnit will always run. ("-- --phpunit" is the default)

    "test" Commands:
      --build        ... Re-builds the Docker container for testing.
      --docker       ... Force to run using docker, if available.
      --local        ... Force to run using local composer package.

      --diagnose     ... Diagnoses composer.
      --phpcbf       ... Fix the marked sniff violations of PHPCS.
      --psalter      ... Run Psalter to fix Psalm errors (Run psalm --alter).
      --requirement  ... Check package requirement for developing.
      --verbose      ... Displays test results in verbose mode.

      --all ............ Runs all the below options. These options can be
                         specified individualy, 'a la carte'.
        --diagnose
        --coveralls
        --phan
        --phpcs
        --phpmd
        --phpstan
        --phpunit
        --psalm
        --requirement

    Sample:
      Note: Without an option, only tests of PHPUnit will be run.

      $ composer test help
      $ composer test -- --local
      $ composer test -- --docker

      $ composer test -- --all
      $ composer test -- --verbose --all

      $ composer test -- --phpmd
      $ composer test -- --phpstan --psalm
      $ composer test -- --phpmd --psalm --local

HEREDOC
)

# -----------------------------------------------------------------------------
#  Functions
#
#  Notes:
#    - Constant variables that won't be changed are in "CAPITAL_SNAKE_CASES".
#    - Global variables that might be changed are in "lower_snake_cases".
#    - Function names are in "lowerCamelCases()".
#    - "getter" functions begins with "get" and must be used as below to capture
#      the echo(STDOUT/STDERR) output:
#        foo=$(getMyValue)
# -----------------------------------------------------------------------------
buildContainerTest() {
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
    docker-compose -f docker-compose.dev.yml build --no-cache "$NAME_SERVICE_TEST" || {
        echoError '❌  Fail to build test container.'
        exit 1
    }
}

buildPhp5() {
    echo '- Building PHP5 test container image ...'
    name_image_php5=$(getNameImagePhp5)
    name_tag_php5=$(getNameTagPhp5)

    docker build \
        --network host \
        --no-cache \
        -t "${name_image_php5}:${name_tag_php5}" \
        --file ./tests/.testcontainer/Dockerfile.php5 \
        .
    test $? -ne 0 && {
        echoError '❌  Failed to build image'
        exit 1
    }
    return 0
}

echoAlert() {
    echoHR '-'
    echo "💡  ${1}"
    echoHR '-'
}

echoError() {
    echo >&2 "${1}"
}

echoErrorHR() {
    echoHR >&2 '-'
    echo >&2 "  ${1}"
    echoHR >&2 '-'
}

echoFlagOptions() {
    echo "${OPTIONS}"
}

echoHelpOption() {
    echo '- Available Option Flags:'
    echo "    $(echoFlagOptions) (To test all use: --all)"
    echo "    (optional for auto fix use: --psalter --phpcbf)"
}

echoHR() {
    # Draw Horizontal Line
    printf '%*s\n' "${SCREEN_WIDTH}" '' | tr ' ' "${1-=}"
}

echoInfoVersions() {
    echo "- $(php --version | head -1)"
    echo "- $(composer --version)"
}

echoMsg() {
    echo "  ${1}"
    echoHR '-'
}

echoNoNewLine() {
    printf '%s' "$1"
}

echoTitle() {
    echo
    echoHR
    echo "  ${1}"
    echoHR
}

getNameImagePhp5() {
    echo "php5_test"
}

getNameTagPhp5() {
    echo "local"
}

getPathParent() {
    dirname "$(getPathScript)"
}

getPathScript() {
    echo "${PATH_DIR_SCRIPT:?'Path variable must be set before call.'}"
}

getWidthScreen() {
    SCREEN_WIDTH_DEFAULT=80
    eval "$(tput cols 2>/dev/null 1>/dev/null)" && {
        SCREEN_WIDTH=$(tput cols)
    }
    SCREEN_WIDTH=${SCREEN_WIDTH:-$SCREEN_WIDTH_DEFAULT}
    echo "$SCREEN_WIDTH"
}

isComposerInstalled() {
    composer --version 2>/dev/null 1>/dev/null && {
        return 0
    }

    return 1
}

isDockerAvailable() {
    docker version 2>/dev/null 1>/dev/null && {
        return 0
    }

    return 1
}

isDockerInstalled() {
    which docker 2>/dev/null 1>/dev/null && {
        return 0
    }

    return 1
}

isFlagSet() {
    flag_tmp="$1"
    option=$(printf '%s' "$flag_tmp" | tr '[:upper:]' '[:lower:]')
    # Captuire '--option' from given args.
    echo "$list_option_given" | grep "\-\-$option" 2>/dev/null 1>/dev/null
    return $?
}

isInsideContainer() {
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

isInsideTravis() {
    [ "$USER" = 'travis' ] || return 1
    [ "$CI" = 'true' ] || return 1

    ls -a "${HOME}/.travis" 1>/dev/null 2>/dev/null && {
        return 0
    }
    return 1
}

isInstalledPackage() {
    echoNoNewLine "    - Package: ${1} ... "

    name_package="${1:?"No package name defined at ${LINENO}"}"
    which "$name_package" 1>/dev/null && {
        echo 'installed'
        return 0
    }

    path_file_bin_installed_package="./vendor/bin/${1}"
    [ -f "$path_file_bin_installed_package" ] || {
        echo "Package NOT FOUND at: ${path_file_bin_installed_package}"
        return 1
    }

    echo 'installed'
    return 0
}

isPHP8() {
    php -r '(version_compare(PHP_VERSION, "8.0") >= 0) ? exit(0) : exit(1);'
    return $?
}

isRequirementsInstallable() {
    flag_installable_requirements=1
    isComposerInstalled || {
        # composer is a must requirement
        echo 'Composer not installed. This is a must requirement.'
        return 1
    }

    if [ "${1}" = "verbose" ]; then
        indent='    '
        result=$(COMPOSER=composer.json composer install --dry-run 2>&1 3>&1)
        flag_installable_requirements=$?
        echo
        echo "${result}" |
            while read -r line; do
                echo "${indent}${line}"
            done
        echo
    else
        COMPOSER=composer.json composer install --dry-run 2>/dev/null 1>/dev/null
        flag_installable_requirements=$?
    fi

    return $flag_installable_requirements
}

isRequirementsInstalled() {
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

isXdebugAvailable() {
    php --version | grep Xdebug 2>/dev/null 1>/dev/null && {
        return 0
    }
    return 1
}

# Loads Token for COVERALLS
loadConfCoverall() {
    path_file_conf_coveralls='./tests/conf/COVERALLS.env'
    if [ -f "${path_file_conf_coveralls}" ]; then
        # shellcheck source=./tests/conf/COVERALLS.env
        . "$path_file_conf_coveralls"
        export COVERALLS_RUN_LOCALLY="$COVERALLS_RUN_LOCALLY"
        export COVERALLS_REPO_TOKEN="$COVERALLS_REPO_TOKEN"
    else
        echo '- Conf file not found at:' "$path_file_conf_coveralls"
    fi
}

removeContainerPrune() {
    echo '- Removing prune container and images ...'
    docker container prune -f 1>/dev/null
    docker image prune -f 1>/dev/null
}

runCoveralls() {
    echoTitle 'TEST: Code Coverage'
    # Skip if the option wasn't set
    ! isFlagSet 'coveralls' && {
        return 2
    }
    # Check Xdebug extension
    if ! php -v | grep Xdebug 1>/dev/null 2>/dev/null; then
        echo >&2 '- Xdebug extension is not enabled. Skipping the test.'
        return 2
    fi

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
    # shellcheck disable=SC2086
    if
        ./vendor/bin/php-coveralls \
            --config=./tests/conf/coveralls.yml \
            --json_path=./report/coveralls-upload.json \
            --verbose \
            --no-interaction \
            $option_dry_run # fix: https://github.com/vimeo/psalm/issues/4888
    then
        return 0
    else
        # avoid other exit code rather than 0 and 1
        return 1
    fi
}

runDiagnose() {
    echoTitle 'DIAGNOSE: composer'
    # Skip if the option wasn't set
    ! isFlagSet 'diagnose' && {
        return 2
    }
    if composer diagnose; then
        return 0
    else
        # avoid other exit code rather than 0 and 1
        return 1
    fi
}

runPhan() {
    echoTitle 'TEST: Phan'
    # Skip if the option wasn't set
    ! isFlagSet 'phan' && {
        return 2
    }
    if PHAN_DISABLE_XDEBUG_WARN=1 \
        ./vendor/bin/phan \
        --allow-polyfill-parser \
        --config-file ./tests/conf/phan.php; then
        return 0
    else
        # avoid other exit code rather than 0 and 1
        return 1
    fi
}

runPhp5() {
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
    if ! docker image ls | grep "$name_image_php5" | grep "$name_tag_php5" 1>/dev/null 2>/dev/null; then
        buildPhp5
    fi

    echo '- Running container ...'
    docker run \
        --rm \
        -v "$(pwd)/tests:/app/tests" \
        -v "$(pwd)/src:/app/src" \
        -v "$(pwd)/composer.json:/app/composer.json" \
        "${name_image_php5}:${name_tag_php5}"
    exit $?
}

runPhpcbf() {
    echoTitle 'FIX: Fix the marked sniff violations'
    # Skip if the option wasn't set
    ! isFlagSet 'phpcbf' && {
        return 2
    }
    if ./vendor/bin/phpcbf --standard=./tests/conf/phpcs.xml -v; then
        return 0
    else
        # avoid other exit code rather than 0 and 1
        return 1
    fi
}

runPHPCS() {
    echoTitle 'TEST: PHP Code Sniffer (Compliant with PSR2)'
    # Skip if the option wasn't set
    ! isFlagSet 'phpcs' && {
        return 2
    }
    if ./vendor/bin/phpcs --standard=./tests/conf/phpcs.xml -v; then
        return 0
    else
        # avoid other exit code rather than 0 and 1
        return 1
    fi
}

runPHPMD() {
    echoTitle 'TEST: PHPMD (Mess Detector)'
    # Skip if the option wasn't set
    ! isFlagSet 'phpmd' && {
        return 2
    }
    if ./vendor/bin/phpmd ./src ansi ./tests/conf/phpmd.xml; then
        return 0
    else
        # avoid other exit code rather than 0 and 1
        return 1
    fi
}

runPHPStan() {
    echoTitle 'TEST: PHPStan'
    # Skip if the option wasn't set
    ! isFlagSet 'phpstan' && {
        return 2
    }
    if ./vendor/bin/phpstan analyse src --level=max; then
        return 0
    else
        # avoid other exit code rather than 0 and 1
        return 1
    fi
}

runPHPUnit() {
    echoTitle 'TEST: PHPUnit'
    # Skip if the option wasn't set
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
    if ./vendor/bin/phpunit --configuration ./tests/conf/phpunit.xml "$option_testdox"; then
        return 0
    else
        # avoid other exit code rather than 0 and 1
        return 1
    fi
}

runPsalm() {
    # Skip if the option wasn't set
    ! isFlagSet 'psalm' && {
        return 2
    }

    # Psalm fails with relative paths so specify as absolute path
    path_dir_current=$(getPathScript)
    path_dir_parent=$(getPathParent)
    path_file_conf_psalm="${path_dir_current}/conf/psalm.xml"

    title_temp='TEST: PSalm'
    # Set psalter option if specified
    use_alter=''
    isFlagSet 'psalter' && {
        use_alter='--alter'
        title_temp="${title_temp} (w/ alter and issue=all option)"
    }
    echoTitle "${title_temp}"
    if ! test -f "$path_file_conf_psalm"; then
        echoErrorHR "❌  Missing: psalm.xml at: ${path_file_conf_psalm}"
        return 1
    fi
    echo "PATH CONF:${path_file_conf_psalm}"
    echo "PATH PRNT:${path_dir_parent}"
    echo "ALTER: ${use_alter}"
    if
        ./vendor/bin/psalm \
            --config="$path_file_conf_psalm" \
            --root="$path_dir_parent" \
            $use_alter # fix: https://github.com/vimeo/psalm/issues/4888
    then
        return 0
    else
        # avoid other exit code rather than 0 and 1
        return 1
    fi
}

runRequirementCheck() {
    echoTitle 'CHECK: Requirement check for tests'

    # Skip if the option wasn't set
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

runTest() {
    name_test=$1
    # Run test function given
    result_msg=$($2 2>&1)
    result=$?
    # Echo results
    [ $result -eq 0 ] && {
        isFlagSet 'verbose' && echo "${result_msg}"
        echoMsg "✅  ${name_test}: passed"
    }
    [ $result -eq 1 ] && {
        echoError "${result_msg}"
        echoErrorHR "❌  ${name_test}: failed"
        all_tests_passed=1
    }
    [ $result -eq 2 ] && {
        isFlagSet 'verbose' && echo "${result_msg}"
        echoMsg "🛑  ${name_test}: skipped"
    }
}

runTestsInContainer() {
    echo '- Calling test container ...'
    echoTitle 'Running Tests in Container'
    if docker-compose --file docker-compose.dev.yml \
        run \
        -e SCREEN_WIDTH="$SCREEN_WIDTH" \
        "$NAME_SERVICE_TEST" \
        "${@}"; then
        return 0
    else
        # avoid other exit code rather than 0 and 1
        return 1
    fi
}

setFlagsTestAllUp() {
    list_option_given="${list_option_given} $(echoFlagOptions)"
}

setOptionCoverallsDryRun() {
    export COVERALLS_RUN_LOCALLY=1
    # Set dry-run option by default
    option_dry_run='--dry-run'
    isInsideTravis && {
        echo '- Running inside Travis detected. Dry-run option was unflagged.'
        export TRAVIS=${TRAVIS:-true}
        export CI_NAME=${CI_NAME:-travis-ci}
        # Unset dry-run option
        option_dry_run=''
    }
}

setOptionPHPUnitTestdox() {
    option_testdox=''
    [ "$mode_verbose" -eq 0 ] && {
        option_testdox='--testdox'
    }
}

showHelp() {
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
SCREEN_WIDTH=$(getWidthScreen)
export SCREEN_WIDTH

# Set directory path of this script
PATH_DIR_SCRIPT="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)"

# Moving to script's parent directory.
cd "$(getPathParent)" || echo >&2 'Failed to change parent directory.'

# Set all options/args given to this script in lower case
list_option_given=$(printf '%s ' "$@" | tr '[:upper:]' '[:lower:]')

# Set initial result flag
#   0    -> All tests passed
#   else -> Some tests failed
all_tests_passed=0

# -----------------------------------------------------------------------------
#  Flag Option Setting
# -----------------------------------------------------------------------------

# Show help
# '--help' was registered for composer's help, so capture 'help' as an exception.
echo "$list_option_given" | grep 'help' && {
    showHelp
    exit $?
}

isFlagSet 'php5' && {
    isInsideContainer && {
        echoError '❌  You can not run "php5" option inside the container.'
        exit 1
    }
    runPhp5
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
        echo '- To specify use: --local or --docker'
        list_option_given="${list_option_given} --docker"
    }
}

# Set verbose mode global
#   0    -> yes
#   else -> no
mode_verbose=1
isFlagSet 'verbose' && {
    mode_verbose=0
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
        if isDockerAvailable; then
            echoErrorHR '💡  Docker is installed and available.'
            echoError '  - Consider running without "--local" option.'
        else
            echoErrorHR '💡  Docker is installed but it is not available to use.'
            echoError '  - Docker engine might be down. Check if Docker is running.'
        fi
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
composer dump-autoload --no-plugins

# Set minimum test
list_option_given="${list_option_given} --phpunit"

# Alert if verbose flag is false(not 0)
[ $mode_verbose -ne 0 ] && {
    echoAlert 'For detailed output, use: --verbose'
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
