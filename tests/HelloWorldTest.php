<?php
declare(strict_types=1);

namespace KEINOS\HelloWorld;

use \KEINOS\Tests\TestCase;

final class ClassHelloWorldTest extends TestCase
{
    public function testRegularInput()
    {
        $subject = new HelloWorld();

        $expect = 'Hello, World!';
        $this->expectOutputString($expect);
        echo $subject->to('World');
    }

    public function testAnotherInput()
    {
        $subject = new HelloWorld();

        $expect = 'Hello, Miku!';
        $this->expectOutputString($expect);
        echo $subject->to('Miku');
    }
}
