<?php
declare(strict_types=1);

namespace KEINOS\HelloWorld;

final class Hello
{
    public function to(string $name): string
    {
        return sayHelloTo($name);
    }
}
