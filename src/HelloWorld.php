<?php
declare(strict_types=1);

namespace KEINOS\HelloWorld;

final class HelloWorld
{
    public function to(string $name):string
    {
        return "Hello, ${name}!";
    }
}
