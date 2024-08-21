#!/usr/bin/env bash
# Test whether the access token and secret pair work by calling
# Launchpad APIs that require authorization
#
# Copyright 2024 林博仁(Buo-ren Lin) <buo.ren.lin@gmail.com>
# SPDX-License-Identifier: MIT

# The consumer key defined by you
CONSUMER_KEY="${CONSUMER_KEY:-unset}"

# The access token acquired from the get-access-token program
OAUTH_ACCESS_TOKEN="${OAUTH_ACCESS_TOKEN:-unset}"

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
    # For initiate an API request
    curl

    # For generating the timestamp required by the OAuth standard
    date

    # For generating the nonce required by the OAuth standard
    md5sum

    # For beautifying JSON API response
    jq

    # For querying the absolute path of the program
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

printf 'Info: Checking the runtime parameters...\n'
required_parameters=(
    CONSUMER_KEY
    OAUTH_ACCESS_TOKEN
)
required_parameter_check_failed=false
for parameter in "${required_parameters[@]}"; do
    if test "${!parameter}" == unset; then
        printf \
            'Error: This program requires the %s parameter to be set.\n' \
            "${parameter}" \
            1>&2
        required_parameter_check_failed=true
    fi
done
if test "${required_parameter_check_failed}" == true; then
    printf 'Error: Required parameter validation failed.\n' 1>&2
    exit 1
fi

printf \
    'Info: Please enter the OAuth token secret you got from the get-access-token program: '
if ! read -r oauth_token_secret; then
    printf \
        'Error: Unable to receive input of the OAuth token secret.\n' \
        1>&2
    exit 2
fi

# If not in terminal consequent output will follow after the prompt
# instead in the new line, workaround it.
if ! test -t 1; then
    printf '\n'
fi

if test -z "${oauth_token_secret}"; then
    printf \
        'Error: Invalid oauth_token_secret(%s) received.\n' \
        "${oauth_token_secret}" \
        1>&2
    exit 1
fi

printf \
    'Info: Querying the Unix epoch timestamp...\n'
if ! timestamp="$(date +%s)"; then
    printf 'Error: Unable to query the Unix epoch timestamp.\n' 1>&2
    exit 2
fi
printf \
    'Info: Unix epoch timestamp determined to be "%s".\n' \
    "${timestamp}"

printf \
    'Info: Generating the nonce string...\n'
if ! nonce_raw="$(md5sum <<< "${timestamp}")"; then
    printf \
        'Error: Unable to generate the MD5 hash of the "%s" timestamp.\n' \
        "${timestamp}" \
        1>&2
    exit 2
fi
nonce="${nonce_raw%% *}"
printf 'Info: Nonce determined to be "%s".\n' "${nonce}"

printf 'Info: Calling Launchpad API...\n'
urlencoded_ampersand='%26'
authorization_string='OAuth '
authorization_string+='realm="https://api.launchpad.net/"'
authorization_string+=", oauth_consumer_key=\"${CONSUMER_KEY}\""
authorization_string+=", oauth_token=\"${OAUTH_ACCESS_TOKEN}\""
authorization_string+=', oauth_signature_method="PLAINTEXT"'
authorization_string+=", oauth_signature=\"${urlencoded_ampersand}${oauth_token_secret}\""
authorization_string+=", oauth_timestamp=\"${timestamp}\""
authorization_string+=", oauth_nonce=\"${nonce}\""
authorization_string+=', oauth_version="1.0"'
curl_opts=(
    --header 'Accept: application/json'
    --header "Authorization: ${authorization_string}"

    # Exit with error if the server returns an error reponse with
    # response body preserved
    --fail-with-body

    # Don't print progress message but still print error
    --silent
    --show-error
)
if ! response="$(
    curl "${curl_opts[@]}" https://api.launchpad.net/beta/bugs/11
    )"; then
    printf \
        'Error: Unable to call the Launchpad API:\n%s\n.' \
        "${response}" \
        1>&2
    exit 2
fi

jq_opts=()
if test -t 1; then
    # Show colored output when using terminal
    jq_opts+=(--color-output)
fi
if ! response_beautified="$(
    jq "${jq_opts[@]}" . <<<"${response}"
    )"; then
    printf 'Error: Unable to generate beautified API response.\n' 1>&2
    exit 2
fi

printf \
    'Info: API call successful, response:\n%s\n' \
    "${response_beautified}"

printf 'Info: Operation completed without errors.\n'
