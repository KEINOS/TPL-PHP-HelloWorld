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
echo '- Commands available:'
echo '    Run Unit Tests   : $ composer test'
echo '    Run All tests    : $ composer test -- --all'
echo '    View all commands: $ composer test help'
echo '- "shfmt" will be automaitcally installed when .sh file was opened on VSCode'
echo '- Auto format: Press option+Shift+f'
