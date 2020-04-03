<?php
/**
 * This script asks the user (or vendor) and the package name, then replaces the string "KEINOS/HelloWorld" in the files of this repo to them.
 *
 * NOTE:
 *   This script must be called only from the command `composer create-project`. Check "scripts" in `/composer.json`.
 */

echo 'Initializing package via composer create-project command' . PHP_EOL;
echo 'Results of "phpinfo()":' . PHP_EOL;
echo phpinfo();
