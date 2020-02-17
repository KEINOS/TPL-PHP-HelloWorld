#!/bin/sh

# =============================================================================
#  Setup
# =============================================================================

cd $(cd $(dirname $0); pwd)

# Set width
if [ -n "${TERM}" ];
    then SCREEN_WIDTH=$(tput cols);
    else SCREEN_WIDTH=80;
fi

all_tests_passed=0

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

# =============================================================================
#  Main
# =============================================================================

echoTitle 'Diagnose: composer'
composer diagnose 1>/dev/null
if [ $? -eq 0 ];
    then echoMsg 'Diagnose: passed'
    else {
        echoMsg 'Diagnose: failed'
        all_tests_passed=1
    }
fi

echoTitle 'TEST: PHPUnit'
./vendor/bin/phpunit
if [ $? -eq 0 ];
    then echoMsg 'PHPUnit: passed';
    else {
        echoMsg 'PHPUnit: failed'
        all_tests_passed=1
    }
fi

echoTitle 'TEST: Code Coverage'
./vendor/bin/php-coveralls --verbose --dry-run
if [ $? -eq 0 ];
    then {
        echoMsg 'COVERALLS: finished'
        cat ./report/clover.xml
        cat ./report/coveralls-upload.json
    };
    else {
        echoMsg 'COVERALLS: failed'
        all_tests_passed=1
    }
fi

echoTitle 'TEST: PHPStan'
./vendor/bin/phpstan analyse src --level=max
if [ $? -eq 0 ];
    then echoMsg 'PHPStan: passed';
    else {
        echoMsg 'PHPStan: failed'
        all_tests_passed=1
    }
fi

echoTitle 'TEST: PSalm w/fix issue'
./vendor/bin/psalm --alter --issues=all
if [ $? -eq 0 ];
    then echoMsg 'PSalm: passed';
    else {
        echoMsg 'PSalm: failed'
        all_tests_passed=1
    }
fi

echoTitle 'TEST: Phan'
./vendor/bin/phan --allow-polyfill-parser
if [ $? -eq 0 ];
    then echoMsg 'Phan: passed';
    else {
        echoMsg 'Phan: failed'
        all_tests_passed=1
    }
fi

if [ $all_tests_passed -eq 0 ];
    then echoTitle '✅ All tests passed.'
    else echoTitle '❌ Some tests failed.'
fi

exit $all_tests_passed