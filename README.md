[![Build Status](https://travis-ci.org/KEINOS/TPL-PHP-HelloWorld.svg?branch=master)](https://travis-ci.org/KEINOS/TPL-PHP-HelloWorld/builds)
[![Coverage Status](https://coveralls.io/repos/github/KEINOS/TPL-PHP-HelloWorld/badge.svg)](https://coveralls.io/github/KEINOS/TPL-PHP-HelloWorld)

# Hello-World Class Template

This repo is a template of Hello-World class, which is overly cautious and includes the following tests.

## Tests

- Supported PHP Version to test
  - PHP v7.1.23, 7.1.33, 7.2.27, 7.3.14, 7.4.2(, nightly)
  - Details see: [.travis.yml](./.travis.yml) and [docker-compose.yml](./docker-compose.yml)
  - Note: The nightly build version fails purposely on TravisCI.
- Unit Test & Code Coverage
  - [PHPUnit](https://phpunit.de/)
- PHP Static Analysis
  - [PHPStan](https://github.com/phpstan/phpstan)
  - [PSalm](https://psalm.dev/)
  - [Phan](https://github.com/phan/phan)

## CIs Used

This repo uses the following CIs. On your use, register your repo first and run the tests before any changes made.

- [TravisCI](https://travis-ci.org/)
- [COVERALLS](https://coveralls.io/)

## How To Use The Template

1. Create a new project with [composer](https://getcomposer.org/).

    ```bash
    composer create-project keinos/hello-world-tpl myNewProject
    mv myNewProject
    ```

2. Run the tests to check it's basic test functionality.

    ```bash
    composer test local
    ```

    ```bash
    # For Docker users
    composer test
    ```

3. Create an empty Git repository and commit them.

    ```bash
    git init
    git add .
    git commit -m 'initial commit'
    ```

4. Push the repo to GitHub then register it to the following CIs.
    - TravisCI
    - COVERALLS

5. Re-name `ENVFILE.env.sample` to `ENVFILE.env`
6. Get your access token from COVERALLS' settings and replace the token value in `ENVFILE.env`.
7. Run tests again to see COVERALLS' function.
8. If the local test passes then commit changes and push.
9. If the tests passes on CIs then start building your project.

## VSCode

If you use Visual Studio Code then you can use "Remote - Containers" extension to develop over Docker container.

Install Microsoft's "Remote - Containers" and "Open Folder in Container" by F1 -> "Remote-Containers".
