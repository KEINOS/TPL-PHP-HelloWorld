<?php

namespace KEINOS\Tests;

// phpcs:disable
// Treat warning as exception
set_error_handler(function ($error_number, $error_str, $error_file, $error_line) {
    $msg  = "Error #${error_number}: ${error_str} on line ${error_line} in file ${error_file}";
    throw new \RuntimeException($msg);
});

if (version_compare(PHP_VERSION, '7.0.0') >= 0) {
    abstract class TestCase extends \PHPUnit\Framework\TestCase
    {
    }
} else {
    class TestCase extends \PHPUnit_Framework_TestCase
    {
    }
}
