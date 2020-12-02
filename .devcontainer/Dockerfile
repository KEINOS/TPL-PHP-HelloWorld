# [Choice] PHP version: 7, 7.4, 7.3
ARG VARIANT="7.3"

# Main stage
# -----------------------------------------------------------------------------
# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.148.1/containers/php/.devcontainer/base.Dockerfile
FROM mcr.microsoft.com/vscode/devcontainers/php:0-${VARIANT}

# Install Node.js(Needs for some extensions)
ARG INSTALL_NODE="true"
ARG NODE_VERSION="lts/*"
RUN if [ "${INSTALL_NODE}" = "true" ]; then su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# Install additional OS packages.
# RUN apt-get update \
#     && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends \
#       <your-package-list-here>

# Update/downgrade PHP Composer from v2 to v1
RUN sudo composer self-update 1.10.17 && composer --version

# Install BOX3 and set path to composer bin as vscode user
USER vscode
RUN whoami \
  && composer global init --stability=dev --quiet \
  && cd ~/.composer \
  && composer require \
    humbug/box:@stable \
    phan/phan:@stable \
    php-coveralls/php-coveralls:@stable \
    phpbench/phpbench:dev-master \
    phpmd/phpmd:@stable \
    phpstan/extension-installer:@stable \
    phpstan/phpstan:@stable \
    phpunit/phpunit:@stable \
    psalm/phar:@stable \
    squizlabs/php_codesniffer:@stable \
  && echo 'export PATH="${HOME}/.composer/vendor/bin:${PATH}"' >> ~/.bashrc

ENV COMPOSER='composer.dev.json'

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1