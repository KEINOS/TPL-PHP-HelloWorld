<?php
declare(strict_types=1);

namespace KEINOS\HelloWorld;

function sayHelloTo(string $name): string {
    return "Hello, ${name}!";
}
