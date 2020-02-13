#!/bin/sh

. ./setup-composer.sh

composer validate && \
composer update php && \
./vendor/bin/phpunit && \
./vendor/bin/phpstan analyse src --level=max && \
./vendor/bin/psalm --alter --issues=all && \
./vendor/bin/phan --allow-polyfill-parser
