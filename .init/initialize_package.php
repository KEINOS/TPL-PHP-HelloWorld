#!/usr/bin/env php
<?php
/**
 * This script will re-write the file name and contents from the template ones to user given one.
 *
 * Package name:
 *   The package name will be replaced from "HelloWorld" to the parent directory name. Which is
 *   the repository's directory name.
 * User/Vendor name:
 *   - If the user/vendor name is given from STDIN (such as via pipe) or the first argument, that
 *     name will rename all the string "KEINOS" to the provided one.
 *   - If not then it will ask the user/vendor name and replace "KEINOS" to the provided one.
 *
 * NOTE:
 *   This script must be called only from the command `composer create-project`.
 *   Check "scripts" key value in `/composer.json`.
 */

echo '------------------------------------------------------------' . PHP_EOL;
echo ' Initializing package via "composer create-project" command' . PHP_EOL;
echo '------------------------------------------------------------' . PHP_EOL;

const DIR_SEP = DIRECTORY_SEPARATOR;

// ============================================================================
//  Preparation
// ============================================================================

// List of files that are expected to exist in the root dir of the package
$list_files_in_root_expect = [
    'README.md',
    'LICENSE',
    'Dockerfile',
    'composer.json',
    'src',
];
$path_dir_package = getPathDirRootOfPackage($list_files_in_root_expect);

// Set package name to replace
$name_pkg_from = 'HelloWorld';
$name_pkg_to   = ucfirst(basename($path_dir_package));

// Set names of vendor to replace
$name_vendor_from = 'KEINOS';
$name_vendor_to   = getNameVendor(); // Get or ask user the name of vendor

// Set namespace
$namespace_from = "${name_vendor_from}/${name_pkg_from}";
$namespace_to   = "${name_vendor_to}/${name_pkg_to}";

// List of files and dirs to exclude when renaming
$list_exclude_file = [
    basename(__FILE__),
    '.git',
    'vendor',
];

// List of pairs to replace names from-to
$list_before_after = [
    [
        'before' => $name_vendor_from,
        'after'  => $name_vendor_to,
    ],
    [
        'before' => $name_pkg_from,
        'after'  => $name_pkg_to,
    ],
];

// ============================================================================
//  Main
// ============================================================================

// Get only files
$list_path_file_replace = getListPathFilesAll($path_dir_package, $list_exclude_file);

try {
    foreach ($list_path_file_replace as $path_file_current) {
        // Rewrite contents
        if (is_file($path_file_current)) {
            echo 'Now renaming contents... ';
            // Rewrite contents
            rewriteFileContents($path_file_current, $list_before_after);
        }

        // Rewrite file name
        rewriteFileName($path_file_current, $name_pkg_from, $name_pkg_to);
    }

    $last_line = exec('composer dump-autoload', $output, $return_var);
    if ($return_var !== 0) {
        $msg_error = implode(PHP_EOL, $output);
        throw new \RuntimeException($msg_error);
    }
} catch (\RuntimeException $e) {
    echo 'ERROR: ', PHP_EOL,  $e->getMessage(), "\n";
}

exit(0);

// ============================================================================
//  Functions
// ============================================================================

function askAgainIfSure($string)
{
    echo '- Are you sure? (Y/n/quit):';
    $input  = strtolower(trim(fgets(STDIN)));
    $result = $input[0];

    if ($result === 'y') {
        return true;
    }

    if ($result === 'q') {
        throw new \RuntimeException(
            "Initialization aborted." . PHP_EOL .
            "- Vendor name and namespaces NOT changed." . PHP_EOL .
            "- You will need to change them your own." . PHP_EOL
        );
    }

    return false;
}

function askUserNameVendor()
{
    global $name_vendor_from;

    do {
        echo '-----------------------' . PHP_EOL;
        echo ' Your name/Vendor name ' . PHP_EOL;
        echo '-----------------------' . PHP_EOL;
        echo "  NOTE: This will replace all the string \"${name_vendor_from}\" to yours. Including namespaces." . PHP_EOL;
        echo '- Input your name/vendor name: ';
        $name_vendor = trim(fgets(STDIN));

        if (! empty($name_vendor)) {
            echo PHP_EOL . 'Vendor name will be: ', $name_vendor, PHP_EOL;
            $name_vendor = (askAgainIfSure($name_vendor)) ? $name_vendor : '';
        } else {
            echo '* ERROR: Vendor name empty. Try again.' . PHP_EOL;
            sleep(1);
        }
    } while (empty(trim($name_vendor)));

    return $name_vendor;
}

function getListPathFilesAll(string $path, array $list_exclude): array
{
    $path_dir = getPathDirReal($path);
    $pattern  = $path_dir . DIR_SEP . '{*,.[!.]*,..?*}'; // Search dot files/dir also but not '.' and '..'
    $result   = [];

    foreach (glob($pattern, GLOB_BRACE) as $path_file) {
        if (in_array(basename($path_file), $list_exclude)) {
            continue;
        }
        if (is_dir($path_file)) {
            $result = array_merge($result, getListPathFilesAll($path_file, $list_exclude));
            continue;
        }
        if (! is_writable($path_file)) {
            throw new \RuntimeException(
                'Given path is not writable.' . PHP_EOL .
                 '- Path: ' . $path_file . PHP_EOL
            );
        }

        $result[] = $path_file;
    }

    return $result;
}

function getNameFromArg()
{
    global $argc, $argv;

    if ($argc === 1) {
        return '';
    }

    return $argv[1];
}

function getNameFromSTDIN()
{
    return (\posix_isatty(STDIN)) ? '' : \file_get_contents('php://stdin');
}

function getNameVendor()
{
    // STDIN
    $name_vendor = trim(getNameFromSTDIN());
    if (! empty($name_vendor)) {
        return $name_vendor;
    }
    // ARG
    $name_vendor = trim(getNameFromArg());
    if (! empty($name_vendor)) {
        return $name_vendor;
    }
    // User input
    $name_vendor = askUserNameVendor();
    if (! empty($name_vendor)) {
        return $name_vendor;
    }
}

function getPathDirRootOfPackage($list_files_in_root)
{
    // Expecting this file is set under /init in the package
    $path_dir_parent = dirname(__DIR__);

    foreach ($list_files_in_root as $name_file) {
        $path = $path_dir_parent . DIR_SEP . $name_file;
        if (! \file_exists($path)) {
            throw new \RuntimeException("Expected file in root dir of the package is missing.\n Missing file: ${path}\n");
        }
    }

    return $path_dir_parent;
}

function getPathDirReal(string $path): string
{
    if (empty(trim($path))) {
        throw new InvalidArgumentException('Empty argument. The given path is empty.');
    }

    $path = \realpath($path);
    if ($path === false) {
        throw new InvalidArgumentException('Invalid path given. Path: ' . $path);
    }
    if (! is_dir($path)) {
        throw new InvalidArgumentException('Given path is not a directory. Path: ' . $path);
    }
    if (! is_readable($path)) {
        throw new \RuntimeException('Given path is not readable. Path: ' . $path);
    }

    return $path;
}

function rewriteFileContents(string $path_file, array $list_before_after)
{
    if (! is_file($path_file)) {
        throw new \RuntimeException('Given path is not a file. Path: ' . $path_file);
    }

    $data_original = \file_get_contents($path_file);
    if ($data_original === false) {
        throw new \RuntimeException('Fail to read file. Path: ' . $path_file);
    }

    $flag_needs_save = false;

    $data_target     = rewriteNameSpace($data_original);
    $flag_needs_save = ($data_target !== $data_original);

    foreach ($list_before_after as $substitute) {
        $from = $substitute['before'];
        $to   = $substitute['after'];
        if (strpos($data_target, $from) !== false) {
            $data_target     = str_replace($from, $to, $data_target);
            $flag_needs_save = true;
        }
    }

    if ($flag_needs_save === true) {
        $result = \file_put_contents($path_file, $data_target, LOCK_EX);
        if ($result === false) {
            throw new \RuntimeException('Fail to save/overwrite data to file:' . $path_file);
        }
        echo 'OK ... ' . $path_file . PHP_EOL;
    } else {
        echo 'SKIP ... ' . $path_file . PHP_EOL;
    }
}

function rewriteFileName($path_file_from, $name_file_from, $name_file_to)
{
    // Find if the file name includes package name. Skip if not.
    $name_file_target = basename($path_file_from);
    if (strpos($name_file_target, $name_file_from) === false) {
        return false;
    }
    // New path to re-write
    $name_file_new = str_replace($name_file_from, $name_file_to, $name_file_target);
    $path_file_new = dirname($path_file_from) . DIR_SEP . $name_file_new;

    // Rename!
    $result = rename($path_file_from, $path_file_new);
    if ($result === false) {
        throw new \RuntimeException(
            'Fail to change file name.' . PHP_EOL .
            '- Original file path: ' . $path_file_from . PHP_EOL .
            '- Name to be replaces: ' . $name_file_to . PHP_EOL
        );
    }
}

function rewriteNameSpace($script)
{
    global $namespace_from, $namespace_to;

    return str_replace($namespace_from, $namespace_to, $script);
}
