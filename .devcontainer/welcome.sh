#!/bin/bash

# This script displays a welcome message when bash shell was called.
# Place messages/infos here to help user what commands are available to use this
# container.

echo '-------------------------------------------------------------------------------'
echo ' PHP Development Container for VSCode Remote - Containers'
echo '-------------------------------------------------------------------------------'
echo "- PHP ver: $(php -r 'echo phpversion();')"
echo "- Shell: ${SHELL}"
echo "- User: $(whoami)"
echo '- To run tests:'
echo '    Run Unit Tests   : $ composer test'
echo '    Run all tests    : $ composer test all'
echo '    Verbose output   : $ composer test all verbose'
echo '    View all commands: $ composer test help'
echo '    Run shellcheck   : $ composer shellcheck'
echo '- Shfmt will be automaitcally installed when .sh file was opened'
echo '- Press option+Shift+f to auto-format'
