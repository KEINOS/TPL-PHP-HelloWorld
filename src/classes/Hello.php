<?php

namespace KEINOS\MyPackageName;

final class Hello
{
    public function to(string $name): string
    {
        return \KEINOS\MyPackageName\sayHelloTo($name);
    }
}
