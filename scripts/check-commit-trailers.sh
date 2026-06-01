#!/usr/bin/env sh
set -eu

range="${1:-HEAD}"

missing=0
for commit in $(git rev-list "$range"); do
    body=$(git log -1 --format=%B "$commit")
    if ! printf '%s\n' "$body" | grep -Eq '^Signed-off-by: .+ <.+>$'; then
        printf 'Missing Signed-off-by trailer: %s\n' "$commit" >&2
        missing=1
    fi
    if printf '%s\n' "$body" | grep -Eq '^Assisted-by:'; then
        if ! printf '%s\n' "$body" | grep -Eq '^Assisted-by: [^[:space:]].+'; then
            printf 'Malformed Assisted-by trailer: %s\n' "$commit" >&2
            missing=1
        fi
    fi
done

exit "$missing"
