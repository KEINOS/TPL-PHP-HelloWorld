[![Build Status](https://travis-ci.org/KEINOS/TPL-PHP-HelloWorld.svg?branch=master)](https://travis-ci.org/KEINOS/TPL-PHP-HelloWorld/builds)
[![Coverage Status](https://coveralls.io/repos/github/KEINOS/TPL-PHP-HelloWorld/badge.svg)](https://coveralls.io/github/KEINOS/TPL-PHP-HelloWorld)
[![](https://img.shields.io/scrutinizer/quality/g/KEINOS/TPL-PHP-HelloWorld/master)](https://scrutinizer-ci.com/g/KEINOS/TPL-PHP-HelloWorld/build-status/master "Scrutinizer code quality")
[![](https://img.shields.io/packagist/php-v/keinos/hello-world-tpl)](https://github.com/KEINOS/TPL-PHP-HelloWorld/blob/master/.travis.yml "Version Support")

# Super cautious "Hello-World"

This repo is an overly cautious [Hello-World PHP script](./src/Main.php) for fun. It includes the following tests and CIs to just say "Hello-World!".

## Tests

- Supported PHP Version to test
  - PHP v7.1, 7.2, 7.3, 7.4 (, nightly)
  - Details see: [.travis.yml](./.travis.yml)
  - Note: The nightly build version (PHP8-dev) fails on purpose in TravisCI.
- Unit Test & Code Coverage
  - [PHPUnit](https://phpunit.de/)
- Coding Standard Compliance (PSR-2)
  - [PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer)
- PHP Static Analysis
  - [PHPStan](https://github.com/phpstan/phpstan)
  - [PSalm](https://psalm.dev/)
  - [Phan](https://github.com/phan/phan)
- Docker for Local Testing
  - Details see: [docker-compose.yml](./docker-compose.yml)

## CIs Used

This repo uses the following CIs. On your use, register your repo first.

- [TravisCI](https://travis-ci.org/): Used for running tests.
- [COVERALLS](https://coveralls.io/): Used for code coverage.
- [Scrutinizer CI](https://scrutinizer-ci.com/): Used for code quality.

# Using this package as a template/boilerplate

<details><summary>How to</summary><div><br>

## How to use it as a template

1. Choose one of the below command that suits you, to create a new project following your project name. (Ex. MyNewProject)

    ```bash
    # For composer user (No Docker)
    composer create-project keinos/hello-world-tpl MyNewProject
    cd MyNewProject
    ```

    ```bash
    # For composer and Docker user
    composer create-project --no-dev keinos/hello-world-tpl MyNewProject
    cd MyNewProject
    ```

    ```bash
    # For Docker and docker-compose user (No PHP nor composer user)
    git clone https://github.com/KEINOS/TPL-PHP-HelloWorld.git MyNewProject
    cd MyNewProject
    rm -rf .git
    ```

    **Note** that the project name provided (the "MyNewProject" above) will be the package name and the namespace such as "MyVendorName/MyNewProject".

2. Run the script below, which will re-write the package and vendor names to the provided name. (Ex. MyVendorName)

    ```bash
    ./.init/initialize_package.php MyVendorName
    ```

3. Before anything, run the tests to check it's basic test functionality.

    ```bash
    composer test local all
    ```

    ```bash
    # For Docker users
    composer test all
    ```

4. Create an empty Git repository and commit them.

    ```bash
    git init
    git add .
    git commit -m 'initial commit'
    ```

5. Push the repo to GitHub then register it to the following CIs.
    - [TravisCI](https://travis-ci.org/)
    - [COVERALLS](https://coveralls.io/)

6. Re-name `ENVFILE.env.sample` to `ENVFILE.env`

7. Get your access token from COVERALLS' settings and place/replace the token value in `ENVFILE.env`.

8. Run tests again to see COVERALLS' function.

9. If the local test passes then commit changes and push.

10. If the tests passes on CIs then start building your project.

## Developing via Docker

This repo can be develop via Docker.


## VS Code and Docker User

If you use Visual Studio Code (a.k.a. VS Code) and have Docker installed, you can use **"Remote - Containers" extension** to develop your project over Docker container.

In this case, you don't need to install the packages or even PHP on your local env.

1. Install Microsoft's ["Remote - Containers"](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension to your VS Code.
2. `git clone` this repo to your local.
3. Remove the `.git` directory and initialize as a new one by `git init`.
4. In VSCode, open the folder in Container by F1 -> "Remote-Containers".

</div></details>

## Credit

This repo was very much inspired by:

- [このPHPがテンプレートエンジンのくせに慎重すぎる](https://qiita.com/search?utf8=%E2%9C%93&sort=&q=title%3A%E3%81%93%E3%81%AEPHP%E3%81%8C%E3%83%86%E3%83%B3%E3%83%97%E3%83%AC%E3%83%BC%E3%83%88%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%B3%E3%81%AE%E3%81%8F%E3%81%9B%E3%81%AB%E6%85%8E%E9%87%8D%E3%81%99%E3%81%8E%E3%82%8B) @ Qiita
