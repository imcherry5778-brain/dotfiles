#!/bin/sh
# Called only by chezmoi run scripts; stdout is evidence, stdin is machine context.
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)
. "$repo/scripts/unix/bootstrap.sh"
bootstrap_runtime "$repo"
exec "$bootstrap_mise" -C "$repo/scripts/unix" exec -- python "$repo/scripts/unix/install.py" --stage "$1"
