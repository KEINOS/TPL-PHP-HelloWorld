<?php

namespace KEINOS\Tests;

final class FunctionSayHelloToTest extends TestCase
{
    public function testWorld()
    {
        $this->assertSame('Hello, World!', \KEINOS\MyPackageName\sayHelloTo('World'));
    }

    public function testMiku()
    {
        $this->assertSame('Hello, Miku!', \KEINOS\MyPackageName\sayHelloTo('Miku'));
    }
}
