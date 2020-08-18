#!/bin/sh

composer dump-autoload && \
/root/.composer/vendor/bin/phpunit \
    --bootstrap=/app/vendor/autoload.php \
    --colors=auto \
    --testdox \
    /app/tests
