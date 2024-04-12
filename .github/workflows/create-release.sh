#!/usr/bin/env bash

echo "GITHUB variables:"
for github_var in "${!GITHUB_@}"
do
    [ "${github_var}" = "GITHUB_TOKEN" ] && continue
    printf "%30s: '%s\n" "${github_var}" "${!github_var}"
done

if ! [ -f "lint-commit-msg" ]
then
    echo "No such file: lint-commit-msg"
    echo "Are you running the script in the repository root?"
    exit 1
fi

version="${1:-${GITHUB_REF_NAME}}"
hash="${2:-${GITHUB_SHA}}"
hash="${hash:0:7}"

echo "Making release"
echo "version: '${version}'"
echo "   hash: '${hash}'"

version_regex='^v[0-9]+[.][0-9]+[.][0-9]+$'
if ! [[ "${version}" =~ ${version_regex} ]]
then
    echo "Invalid version: '${version}'"
    exit 1
fi

hash_regex='^[a-f0-9]{7}$'
if ! [[ "${hash}" =~ ${hash_regex} ]]
then
    echo "Invalid hash: '${hash}'"
    exit 1
fi

mkdir -p build || exit 1
sed -E "s/^# lint-commit-msg @\{version information\} .*$/# lint-commit-msg ${version} (${hash})/" \
    lint-commit-msg > build/lint-commit-msg


echo "Running 'gh release create'"
gh release create "${version}" \
   --repo="${GITHUB_REPOSITORY}" \
   --title="${GITHUB_REPOSITORY#*/} ${version#v}" \
   --generate-notes \
   build/lint-commit-msg
