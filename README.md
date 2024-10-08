# Learning signing Launchpad API requests

Learning signing Launchpad API requests with shell commands.

<https://gitlab.com/brlin/launchpad-api-request-signing-lab>  
[![The GitLab CI pipeline status badge of the project's `main` branch](https://gitlab.com/brlin/launchpad-api-request-signing-lab/badges/main/pipeline.svg?ignore_skipped=true "Click here to check out the comprehensive status of the GitLab CI pipelines")](https://gitlab.com/brlin/launchpad-api-request-signing-lab/-/pipelines) [![GitHub Actions workflow status badge](https://github.com/brlin-tw/launchpad-api-request-signing-lab/actions/workflows/check-potential-problems.yml/badge.svg "GitHub Actions workflow status")](https://github.com/brlin-tw/launchpad-api-request-signing-lab/actions/workflows/check-potential-problems.yml) [![pre-commit enabled badge](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white "This project uses pre-commit to check potential problems")](https://pre-commit.com/) [![REUSE Specification compliance badge](https://api.reuse.software/badge/gitlab.com/brlin/launchpad-api-request-signing-lab "This project complies to the REUSE specification to decrease software licensing costs")](https://api.reuse.software/info/gitlab.com/brlin/launchpad-api-request-signing-lab)

## Usage

1. Pick a consumer key.
1. Get a request token and secret pair by running [the get-request-token.sh program](get-request-token.sh) ([example output](get-request-token.sample.out.txt)).
1. Get a access token and secret pair by running [the get-access-token.sh program](get-access-token.sh) ([example output](get-access-token.sample.out.txt)).
1. Test calling the Launchpad API with the OAuth access token and secret pair by running [the test-access-token.sh program](test-access-token.sh) ([example output](test-access-token.sample.out.txt)).

Refer the file header of each program for the accepted input environment variables.

## References

The following material is referenced during the development of this project:

* [API/SigningRequests - Launchpad Help](https://help.launchpad.net/API/SigningRequests)  
  Explains how to sign Launchpad API requests.
* curl(1) manual page  
  Explains how to use the command-line options of the curl(1) command.
* [Regular expression - Wikipedia](https://en.wikipedia.org/wiki/Regular_expression)  
  Explains what does the `[:print:]` character class do.

## Licensing

Unless otherwise noted(individual file's header/[REUSE.toml](REUSE.toml)), this product is licensed under [the MIT license](https://opensource.org/license/mit), or any of its recent versions you would prefer.

This work complies to [the REUSE Specification](https://reuse.software/spec/), refer the [REUSE - Make licensing easy for everyone](https://reuse.software/) website for info regarding the licensing of this product.
