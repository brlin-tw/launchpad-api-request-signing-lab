#!/usr/bin/env bash
# Let Launchpad authorize the user and request the access token for
# future use
#
# Copyright 2024 林博仁(Buo-ren Lin) <buo.ren.lin@gmail.com>
# SPDX-License-Identifier: MIT

# The request token obtained from the get-request-token program
REQUEST_TOKEN="${REQUEST_TOKEN:-unset}"

# The consumer key you defined from the beginning
CONSUMER_KEY="${CONSUMER_KEY:-"Just testing"}"

# Whether we should request desktop-integration/system-wide access level
SYSTEM_WIDE="${SYSTEM_WIDE:-false}"
OS_NAME="${OS_NAME:-""}"
HOST_NAME="${HOST_NAME:-""}"

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

    # For parsing out the reponse body that contain more than 2
    # parameters
    grep

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
    REQUEST_TOKEN
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

boolean_regex='^(true|false)$'
if ! [[ ${boolean_regex} =~ ${SYSTEM_WIDE} ]]; then
    printf \
        'Error: The value of the SYSTEM_WIDE parameter(%s) should either be "true" or "false".\n' \
        "${SYSTEM_WIDE}" \
        1>&2
    exit 1
fi

if test "${SYSTEM_WIDE}" == true; then
    system_wide_parameter_check_failed=false
    system_wide_parameters=(
        OS_NAME
        HOSTNAME
    )
    for parameter in "${system_wide_parameters[@]}"; do
        if test -z "${!parameter}"; then
            printf \
                'Error: This program requires the %s parameter to be not null.\n' \
                "${parameter}" \
                1>&2
            system_wide_parameter_check_failed=true
        fi
    done
    if test "${system_wide_parameter_check_failed}" == true; then
        printf 'Error: System-wide parameter validation failed.\n' 1>&2
        exit 1
    fi
fi

authorization_url="https://launchpad.net/+authorize-token?oauth_token=${REQUEST_TOKEN}"
if test "${SYSTEM_WIDE}" == true; then
    authorization_url+='&allow_permission=DESKTOP_INTEGRATION'
fi

printf \
    'Info: Please browse the following URL to complete the Launchpad authorization process:\n\n    %s\n\n' \
    "${authorization_url}"
printf 'Info: Press ENTER when you have completed the authorization process:'
# We don't actually use the enter variable here
# shellcheck disable=SC2162,SC2034
if ! read enter; then
    printf \
        'Error: Unable to read the ENTER keystroke.\n' \
        1>&2
    exit 2
fi

printf \
    'Info: Please enter the request token secret you got from the get-request-token program: '
if ! read -r request_token_secret; then
    printf \
        'Error: Unable to receive input of the request token secret.\n' \
        1>&2
    exit 2
fi
if test -z "${request_token_secret}"; then
    printf \
        'Error: Invalid request_token_secret(%s) received.\n' \
        "${request_token_secret}" \
        1>&2
    exit 2
fi

oauth_signature="&${request_token_secret}"
curl_opts=(
    # Send POST request with URL-encoded parameter arguments with the
    # application/x-www-form-urlencoded MIME type
    --data-urlencode "oauth_token=${REQUEST_TOKEN}"
    --data-urlencode "oauth_consumer_key=${CONSUMER_KEY}"
    --data-urlencode oauth_signature_method=PLAINTEXT
    --data-urlencode "oauth_signature=${oauth_signature}"

    # Exit with error if the server returns an error reponse with
    # response body preserved
    --fail-with-body

    # Don't print progress message but still print error
    --silent
    --show-error
)
if ! response="$(
    curl "${curl_opts[@]}" https://launchpad.net/+access-token
    )"; then
    printf \
        'Error: Unable to obtain the access token:\n%s\n.' \
        "${response}" \
        1>&2
    exit 2
fi

oauth_token_regex='(?<=oauth_token=)[^&]+'
grep_opts=(
    # Use the Perl-compatible regular expression(PCRE) that support
    # the lookbehind syntax
    --perl-regexp

    # Only print the matching portion instead of the whole line
    --only-matching
)
if ! oauth_token="$(
    grep \
        "${grep_opts[@]}" \
        --regexp="${oauth_token_regex}" \
        <<<"${response}"
    )"; then
    printf \
        'Error: Unable to parse out the oauth_token from the API response body("%s").\n' \
        "${response}" \
        1>&2
    exit 2
fi

printf \
    'Info: Launchpad has returned the following OAuth token:\n\n    %s\n\n' \
    "${oauth_token}"

oauth_token_secret_regex='(?<=oauth_token_secret=)[^&]+'
if ! oauth_token_secret="$(
    grep \
        "${grep_opts[@]}" \
        --regexp="${oauth_token_secret_regex}" \
        <<<"${response}"
    )"; then
    printf \
        'Error: Unable to parse out the oauth_token_secret from the API response body("%s").\n' \
        "${response}" \
        1>&2
    exit 2
fi

printf \
    'Info: Launchpad has returned the following OAuth token secret:\n\n    %s\n\n' \
    "${oauth_token_secret}"

printf \
    'Info: Operation completed without errors.\n'
