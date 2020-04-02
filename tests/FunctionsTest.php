<?php
declare(strict_types=1);

namespace KEINOS\HelloWorld;

use \KEINOS\Tests\TestCase;

final class FunctionSayHelloToTest extends TestCase
{
    public function testHelloWorld()
    {
        $this->assertSame('Hello, World!', sayHelloTo('World'));
    }

    public function testHelloMiku()
    {
        $this->assertSame('Hello, Miku!', sayHelloTo('Miku'));
    }
}
