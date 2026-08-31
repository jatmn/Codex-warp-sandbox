#!/usr/bin/env bash
set -euo pipefail

root="${1:-$(git rev-parse --show-toplevel)}"
cd "$root"
list="tools/nightly-packaging-contract.txt"
[ -f "$list" ] || { echo 'nightly-contract-digest: contract list is missing' >&2; exit 1; }
temp="$(mktemp)"
trap 'rm -f "$temp"' EXIT

while IFS= read -r input || [ -n "$input" ]; do
  input="${input%$'\r'}"
  case "$input" in ''|'#'*) continue ;; esac
  if [[ "$input" == */ ]]; then
    [ -d "${input%/}" ] || { echo "nightly-contract-digest: missing $input" >&2; exit 1; }
    find "${input%/}" -type f -print
  else
    [ -f "$input" ] || { echo "nightly-contract-digest: missing $input" >&2; exit 1; }
    printf '%s\n' "$input"
  fi
done <"$list" | sort | while IFS= read -r file; do
  file="${file%$'\r'}"
  printf '%s\0%s\n' "$file" "$(bash scripts/sha256-file.sh "$file")"
done >"$temp"
digest="$(bash scripts/sha256-file.sh "$temp")"
[[ "$digest" =~ ^[0-9a-f]{64}$ ]] || { echo 'nightly-contract-digest: invalid digest' >&2; exit 1; }
printf '%s\n' "$digest"
