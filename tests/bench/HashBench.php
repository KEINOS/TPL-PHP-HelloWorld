<?php

declare(strict_types=1);

namespace KEINOS\Bench;

// For more bench settings, see PHPBench manual
// @ref https://phpbench.readthedocs.io/en/latest/writing-benchmarks.html

class HashBench
{
    /**
     * @Revs(1000)
     * @Iterations(5)
     */
    public function benchSha256()
    {
        $dummy = hash('sha256', 'sample');
    }

    /**
     * @Revs(1000)
     * @Iterations(5)
     */
    public function benchSha512()
    {
        $dummy = hash('sha512', 'sample');
    }
}
