#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "$repo/scripts/unix/bootstrap.sh"
bootstrap_runtime "$repo"
test_script="$repo/tests/test-install.py"
if [ "${DOTFILES_PERSONAL_MIGRATION:-0}" = 1 ]; then
  test_script="$repo/tests/fedora-personal-install.py"
fi
exec "$bootstrap_mise" -C "$repo/scripts/unix" exec -- python "$test_script"
