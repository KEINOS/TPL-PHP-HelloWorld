#!/bin/sh
# =============================================================================
#  Script to test the "initialize_package.php" process.
# =============================================================================
#  This script MUST BE RUN inside Docker container.
#  It runs the "initialize_package.php" script with vendor name as "MyVendorName"
#  and then the test. Also note that this script will be deleted by the
#  "initialize_package.php" script.

php /app/.devcontainer/initialize_package.php MyVendorName && \
composer install && \
composer dump-autoload && \
composer test all
[ $? -eq 0 ] && {
    echo
    echo '✅  Initialization script seems to work fine.'
    exit 0
} || {
    echo
    echo '❎  Failed to run initialization script.'
    exit 1
}
