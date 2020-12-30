#!/bin/sh
# =============================================================================
#  Script to test the "initialize_package.php" process.
# =============================================================================
#  This file will be removed in the actual initialization process.
#
#  It runs the "initialize_package.php" script with vendor name as "MyVendorName"
#  and then runs the test. Also note that this script will be deleted by the
#  "initialize_package.php" script.
#
#  Therefore, this script MUST BE COPYED and run inside Docker container and DO
#  NOT MOUNT IT. Otherwise after the process it will delete this file.

if php /app/.devcontainer/initialize_package.php MyVendorName &&
    composer install &&
    composer dump-autoload &&
    composer test all;
then
    echo
    echo '✅  Initialization script seems to work fine.'
    exit 0
else
    echo
    echo '❎  Failed to run initialization script.'
    exit 1
fi
