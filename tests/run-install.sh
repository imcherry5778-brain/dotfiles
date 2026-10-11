#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
. "$repo/scripts/unix/bootstrap.sh"
bootstrap_runtime "$repo"
exec "$bootstrap_mise" -C "$repo/scripts/unix" exec -- python "$repo/tests/test-install.py"
