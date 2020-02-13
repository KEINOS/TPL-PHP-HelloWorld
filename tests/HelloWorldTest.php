<?php
declare(strict_types=1);

namespace KEINOS\HelloWorld;

use KEINOS\HelloWorld\TestCase;

final class HelloTest extends TestCase
{
    public function test()
    {
        $subject = new HelloWorld();

        $this->assertSame('Hello, World!', $subject->to('World'));
        $this->assertSame('Hello, Miku!', $subject->to('Miku'));
    }
}
