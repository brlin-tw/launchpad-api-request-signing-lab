#!/usr/bin/env bash
# Obtain a request token from Launchpad
#
# Copyright 2024 林博仁(Buo-ren Lin) <buo.ren.lin@gmail.com>
# SPDX-License-Identifier: MIT

CONSUMER_KEY="${CONSUMER_KEY:-"Just testing"}"

printf \
    'Info: Configuring the defensive interpreter behaviors...\n'
set_opts=(
    # Terminate script execution when an unhandled error occurs
    -o errexit
    -o errtrace

    # Terminate script execution when an unset parameter variable is
    # referenced
    -o nounset
)
if ! set "${set_opts[@]}"; then
    printf \
        'Error: Unable to configure the defensive interpreter behaviors.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Checking the existence of the required commands...\n'
required_commands=(
    curl
    realpath
)
flag_required_command_check_failed=false
for command in "${required_commands[@]}"; do
    if ! command -v "${command}" >/dev/null; then
        flag_required_command_check_failed=true
        printf \
            'Error: This program requires the "%s" command to be available in your command search PATHs.\n' \
            "${command}" \
            1>&2
    fi
done
if test "${flag_required_command_check_failed}" == true; then
    printf \
        'Error: Required command check failed, please check your installation.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Configuring the convenience variables...\n'
if test -v BASH_SOURCE; then
    # Convenience variables may not need to be referenced
    # shellcheck disable=SC2034
    {
        printf \
            'Info: Determining the absolute path of the program...\n'
        if ! script="$(
            realpath \
                --strip \
                "${BASH_SOURCE[0]}"
            )"; then
            printf \
                'Error: Unable to determine the absolute path of the program.\n' \
                1>&2
            exit 1
        fi
        script_dir="${script%/*}"
        script_filename="${script##*/}"
        script_name="${script_filename%%.*}"
    }
fi
# Convenience variables may not need to be referenced
# shellcheck disable=SC2034
{
    script_basecommand="${0}"
    script_args=("${@}")
}

printf \
    'Info: Setting the ERR trap...\n'
trap_err(){
    printf \
        'Error: The program prematurely terminated due to an unhandled error.\n' \
        1>&2
    exit 99
}
if ! trap trap_err ERR; then
    printf \
        'Error: Unable to set the ERR trap.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Obtaining request token and secret pair using the consumer key "%s"...\n' \
    "${CONSUMER_KEY}"
curl_opts=(
    # Send POST request with URL-encoded parameter arguments with the
    # application/x-www-form-urlencoded MIME type
    --data-urlencode "oauth_consumer_key=${CONSUMER_KEY}"
    --data-urlencode oauth_signature_method=PLAINTEXT
    --data-urlencode 'oauth_signature=&'

    # Exit with error if the server returns an error reponse with
    # response body preserved
    --fail-with-body

    # Don't print progress message but still print error
    --silent
    --show-error
)
if ! response="$(
    curl "${curl_opts[@]}" https://launchpad.net/+request-token
    )"; then
    printf \
        'Error: Unable to obtain the request token and secret pair:\n%s\n.' \
        "${response}" \
        1>&2
    exit 2
fi

printf 'Info: Parsing and validating the request token...\n'
request_token_raw="${response%%&*}"
if test "${request_token_raw}" == "${response}"; then
    printf \
        'Error: Unable to strip out the oauth_token_secret parameter from the API response(%s).\n' \
        "${request_token}" \
        1>&2
    exit 2
fi

request_token="${request_token_raw#oauth_token=}"
if test "${request_token}" == "${request_token_raw}"; then
    printf \
        'Error: Unable to parse out the value of the request_token parameter from request_token_raw(%s).\n' \
        "${request_token_raw}" \
        1>&2
    exit 2
fi

printf \
    'Info: Launchpad has returned the following request token:\n\n    %s\n\n' \
    "${request_token}"

printf \
    'Info: Parsing and validating the request token secret...\n'
request_secret_raw="${response##*&}"
if test "${request_secret_raw}" == "${response}"; then
    printf \
        'Error: Unable to parse out the request secret parameter from the API response(%s).\n' \
        "${response}" \
        1>&2
    exit 2
fi

request_secret="${request_secret_raw#oauth_token_secret=}"
if test "${request_secret}" == "${request_secret_raw}"; then
    printf \
        'Error: Unable to parse out the value of the oauth_token_secret parameter from the request_secret_raw variable(%s).\n' \
        "${request_secret_raw}" \
        1>&2
    exit 2
fi

printf \
    'Info: Launchpad has returned the request token secret:\n\n    %s\n\n' \
    "${request_secret}"

printf \
    'Info: Operation completed without errors.\n'
