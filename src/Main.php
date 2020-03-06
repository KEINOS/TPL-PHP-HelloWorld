<?php
declare(strict_types=1);

namespace KEINOS\HelloWorld;

include_once(__DIR__ . '/../vendor/autoload.php');

use KEINOS\HelloWorld\HelloWorld;

$hello = new HelloWorld();
$name = 'KEINOS';

echo $hello->to($name) . PHP_EOL;
