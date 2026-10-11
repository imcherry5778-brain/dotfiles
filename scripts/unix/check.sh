#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)
for relative in .chezmoiroot home/.chezmoi.toml.tmpl home/.chezmoidata.toml home/.chezmoiignore mise.toml; do
  [ -f "$repo_root/$relative" ] || { printf 'Missing file: %s\n' "$relative" >&2; exit 1; }
done
[ "$(cat "$repo_root/.chezmoiroot")" = 'home' ] || { printf '%s\n' 'Invalid chezmoi source root.' >&2; exit 1; }
grep -qx '\*\*' "$repo_root/home/.chezmoiignore" || { printf '%s\n' 'Foundation deployment boundary is missing.' >&2; exit 1; }
sh -n "$repo_root/install.sh"
sh -n "$repo_root/scripts/unix/check.sh"
printf '%s\n' 'Repository structure and POSIX syntax: OK'

for tool in git mise chezmoi; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf 'Available prerequisite: %s\n' "$tool"
  else
    printf 'Missing future bootstrap prerequisite: %s (not installed by this check)\n' "$tool"
  fi
done
printf '%s\n' 'No user configuration or packages were changed.'
