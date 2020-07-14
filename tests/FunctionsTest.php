<?php

declare(strict_types=1);

namespace KEINOS\Tests;

final class FunctionSayHelloToTest extends TestCase
{
    public function testWorld()
    {
        $this->assertSame('Hello, World!', \KEINOS\HelloWorld\sayHelloTo('World'));
    }

    public function testMiku()
    {
        $this->assertSame('Hello, Miku!', \KEINOS\HelloWorld\sayHelloTo('Miku'));
    }
}
