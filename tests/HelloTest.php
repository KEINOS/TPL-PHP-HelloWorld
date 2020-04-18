<?php
declare(strict_types=1);

namespace KEINOS\HelloWorld;

use \KEINOS\Tests\TestCase;

final class ClassHelloTest extends TestCase
{
    public function testRegularInput()
    {
        $subject = new Hello();

        $expect = 'Hello, World!';
        $this->expectOutputString($expect);
        echo $subject->to('World');
    }

    public function testAnotherInput()
    {
        $subject = new Hello();

        $expect = 'Hello, Miku!';
        $this->expectOutputString($expect);
        echo $subject->to('Miku');
    }
}
