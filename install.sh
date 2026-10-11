#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
case "${1:---plan}" in
  --plan)
    [ "$#" -le 1 ] || { printf '%s\n' 'Unexpected arguments.' >&2; exit 2; }
    printf '%s\n' \
      'dotfiles: Linux/macOS explicit installer; deployment disabled by default' \
      "Repository: $repo_root" \
      '1. Review platform, current configuration and installation ownership.' \
      '2. Prepare OS prerequisites and mise-managed Python automatically during --apply.' \
      '3. Review a fresh configuration diff and create a private targeted backup.' \
      '4. Install missing CLI/apps, apply configuration and verify actual execution.' \
      'Use --apply --profile FILE for the reviewed platform profile; existing providers are preserved.'
    ;;
  --check)
    [ "$#" -eq 1 ] || { printf '%s\n' 'Unexpected arguments.' >&2; exit 2; }
    exec sh "$repo_root/scripts/unix/check.sh"
    ;;
  --apply)
    [ "$#" -eq 3 ] && [ "$2" = '--profile' ] || { printf '%s\n' 'Usage: sh install.sh --apply --profile FILE' >&2; exit 2; }
    [ -f "$3" ] || { printf '%s\n' 'Profile file not found.' >&2; exit 2; }
    . "$repo_root/scripts/unix/bootstrap.sh"
    bootstrap_runtime "$repo_root"
    exec "$bootstrap_mise" -C "$repo_root" exec -- python "$repo_root/scripts/unix/install.py" --profile "$3"
    ;;
  --desktop-only)
    [ "$#" -eq 1 ] || { printf '%s\n' 'Unexpected arguments.' >&2; exit 2; }
    . "$repo_root/scripts/unix/bootstrap.sh"
    bootstrap_runtime "$repo_root"
    exec "$bootstrap_mise" -C "$repo_root" exec -- python "$repo_root/scripts/unix/install.py" --desktop-only
    ;;
  --desktop-plan)
    [ "$#" -eq 1 ] || { printf '%s\n' 'Unexpected arguments.' >&2; exit 2; }
    exec python3 "$repo_root/scripts/unix/install.py" "$1"
    ;;
  --help|-h)
    printf '%s\n' 'Usage: sh install.sh [--plan|--check|--help] | --apply --profile FILE | --desktop-plan | --desktop-only'
    ;;
  *)
    printf '%s\n' 'Unsupported operation. No installation or deployment was performed.' >&2
    exit 2
    ;;
esac
