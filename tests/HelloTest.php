<?php

declare(strict_types=1);

namespace KEINOS\Tests;

use KEINOS\HelloWorld\Hello;

final class ClassHelloTest extends TestCase
{
    public function testRegularInput()
    {
        $sample = new Hello();

        $expect = 'Hello, World!';
        $actual = $sample->to('World');
        $this->assertSame($expect, $actual);
    }

    public function testAnotherInput()
    {
        $sample = new Hello();

        $expect = 'Hello, Miku!';
        $actual = $sample->to('Miku');
        $this->assertSame($expect, $actual);
    }
}
