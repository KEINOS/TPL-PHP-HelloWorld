<?php

// Fix Issue #52: https://github.com/KEINOS/TPL-PHP-HelloWorld/issues/52
return [
    'directory_list' => [
        'src',
        // Un-commnet below and change the path to the package you want to include during the phan analysis.
        //'vendor/netresearch', // Add packages to let phan notice when using "use" in the script.
    ],
    'exclude_analysis_directory_list' => [
        'vendor/' // exclude the other packages
    ],
];
