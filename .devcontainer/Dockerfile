# [Choice] PHP version: 7, 7.4, 7.3
ARG VARIANT='7.3'
# Install node for VS Code extensions
ARG INSTALL_NODE="true"
ARG NODE_VERSION="lts/*"

# Default composer conf file
ARG COMPOSER='composer.json'
ARG COMPOSER_VERSION='1.10.19'

# Main stage
# -----------------------------------------------------------------------------
# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.148.1/containers/php/.devcontainer/base.Dockerfile
FROM mcr.microsoft.com/vscode/devcontainers/php:0-${VARIANT}

ARG COMPOSER
ARG COMPOSER_VERSION
ARG INSTALL_NODE
ARG NODE_VERSION

ENV \
  # This container uses .oh-my-bash for other themes see: https://github.com/ohmybash/oh-my-bash/wiki/Themes
  # VSCode User NOTE: VSCode will override this value. Set the value in devcontainer.json instead.
  OSH_THEME="rana" \
  # Set default composer conf file
  COMPOSER="$COMPOSER" \
  # Set composer version to upgrade/downgrade
  COMPOSER_VERSION="$COMPOSER_VERSION"

# Install additional OS packages.
RUN apt-get update \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends \
    xz-utils \
  # Install shellcheck, the static analysys tool for shell scripts
  && wget -P tmp_install_folder/ https://github.com/koalaman/shellcheck/releases/download/latest/shellcheck-latest.linux.x86_64.tar.xz \
  && tar xvf tmp_install_folder/shellcheck-latest.linux.x86_64.tar.xz -C tmp_install_folder \
  && cp tmp_install_folder/shellcheck-latest/shellcheck /usr/bin/shellcheck \
  && rm -r tmp_install_folder

# Install Node.js(Needs for some extensions)
RUN if [ "${INSTALL_NODE}" = "true" ]; then su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1

# Avoid bash warning: "setlocale: LC_CTYPE: cannot change locale"
RUN \
  sudo localedef -f UTF-8 -i ja_JP ja_JP && \
  sudo localedef -f UTF-8 -i es_MX es_MX

# Xdebug compatibility. See: https://xdebug.org/docs/upgrade_guide
RUN \
  cat /usr/local/etc/php/conf.d/xdebug.ini && \
  # Reset xdebug.ini if xdebug v3.0
  if php -r "exit(version_compare('3.0',phpversion('xdebug'),'>=')?1:0);"; then \
    # Fix: https://travis-ci.community/t/xdebug-3-is-installed-by-default-breaking-builds/10748
    if php -r "exit(version_compare('3.0.0',phpversion('xdebug'),'==')?1:0);"; then \
      pecl install xdebug-3.0.1; \
    fi; \
    path_dir_so_xdebug="$(php -r "echo ini_get('extension_dir');")/xdebug.so" \
      && echo '[xdebug]' > /usr/local/etc/php/conf.d/xdebug.ini \
      && echo "zend_extension=${path_dir_so_xdebug}" >> /usr/local/etc/php/conf.d/xdebug.ini \
      && echo 'xdebug.session=devcontainer' >> /usr/local/etc/php/conf.d/xdebug.ini \
      && echo 'xdebug.mode=coverage' >> /usr/local/etc/php/conf.d/xdebug.ini \
      && echo 'xdebug.discover_client_host=0' >> /usr/local/etc/php/conf.d/xdebug.ini; \
  fi

# Install php-ast
RUN sudo pecl install ast \
  && path_dir_so_ast="$(php -r "echo ini_get('extension_dir');")/ast.so" \
  && echo "extension=${path_dir_so_ast}" > /usr/local/etc/php/conf.d/ast.ini

# Copy the welcome message script for bash
COPY welcome.sh /welcome.sh

# Gloval initialization of composer and set path and welcome message
USER vscode
RUN composer global init --stability=dev --quiet \
  && echo 'export PATH="${HOME}/.composer/vendor/bin:${PATH}"' >> ~/.bashrc \
  && echo 'export PATH="$(pwd)/vendor/bin:${PATH}"' >> ~/.bashrc \
  && echo '/bin/bash /welcome.sh' >> ~/.bashrc
