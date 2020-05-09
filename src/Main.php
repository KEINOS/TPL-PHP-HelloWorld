<?php
/**
 * Main script.
 *
 * Overly-Cautious Development of Hello World!.
 *
 * @standard PSR2
 */
declare(strict_types=1);

namespace KEINOS\HelloWorld;

require_once __DIR__ . '/../vendor/autoload.php';

use KEINOS\HelloWorld\Hello;

$hello = new Hello();
$name  = 'KEINOS';

echo $hello->to($name) . PHP_EOL;
