[![Build Status](https://travis-ci.org/KEINOS/TPL-PHP-HelloWorld.svg?branch=master)](https://travis-ci.org/KEINOS/TPL-PHP-HelloWorld/builds)
[![Coverage Status](https://coveralls.io/repos/github/KEINOS/TPL-PHP-HelloWorld/badge.svg)](https://coveralls.io/github/KEINOS/TPL-PHP-HelloWorld)

# Hello-World Class Template

This repo is a template of Hello-World class, which includes the following tests.

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

1. Copy/Clone/Fork the repo as a new project ether one of the following way.
    - [Use this template](https://github.com/KEINOS/TPL-PHP-HelloWorld/generate) to fork the repo.
    - Clone this repo and delete the `.git` directory then `git init`.
    - Use `composer` as new package.
      - `composer create-project keinos/hello-world-tpl`
2. Push the repo to GitHub then register it to the following CIs.
    - TravisCI
    - COVERALLS
3. Re-name `ENVFILE.env.sample` to `ENVFILE.env`
4. Get your access token from COVERALLS' settings and replace the token value in `ENVFILE.env`.
5. Commit changes and push to see if the tests passes.
6. If the tests passes on CIs then start building your project.

## How To Run Tests

```shellsession
$ composer test
...
```

### General

Commit changes and push. Then the CI runs your tests.

### Local

Using Docker and docker-compose eases your tests. Build the container image then run container/s.

```shellsession
$ # build
$ docker-compose build --no-cache
...
```

```shellsession
$ # Run tests in PHP 7.1.23
$ docker-compose up 7.1.23
...
$ # Run all tests
$ docker-compose up && echo $?
...
```

## VSCode

If you use Visual Studio Code then you can use "Remote - Containers" extension to develop over Docker container.

Install Microsoft's "Remote - Containers" and "Open Folder in Container" by F1 -> "Remote-Containers".
