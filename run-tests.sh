#!/usr/bin/env bash

printf "Running lint-commit-msg tests\n"
printf "bash version: ${BASH_VERSION}\n\n"

if ! ( [ -x lint-commit-msg ] && [ -f lint-commit-msg ] )
then
    echo "ERROR: Cannot find lint-commit-msg"
    echo "Are you in the root directory of the repository?"
    exit 1
fi

export PATH="${PWD}:${PATH}"
cd test || exit 1
timeout 60s ./testrunner cases/*.test
exit_code=$?

echo
[ "${exit_code}" -eq 0 ] && echo SUCCESS || echo "FAILURE (exit code: ${exit_code})"
exit "${exit_code}"
