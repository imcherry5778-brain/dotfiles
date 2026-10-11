#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
case "${1:---plan}" in
  --plan)
    [ "$#" -le 1 ] || { printf '%s\n' 'Unexpected arguments.' >&2; exit 2; }
    printf '%s\n' \
      'dotfiles: foundation phase' \
      "Repository: $repo_root" \
      '1. Review platform, current configuration and installation ownership.' \
      '2. Prepare Git, mise and chezmoi in a separately authorized bootstrap.' \
      '3. Initialize machine data and review a configuration diff.' \
      '4. Apply only the reviewed migration, then install and verify selected tools.' \
      'This entry point currently prints a plan or checks prerequisites only.'
    ;;
  --check)
    [ "$#" -eq 1 ] || { printf '%s\n' 'Unexpected arguments.' >&2; exit 2; }
    exec sh "$repo_root/scripts/unix/check.sh"
    ;;
  --help|-h)
    printf '%s\n' 'Usage: sh install.sh [--plan|--check|--help]'
    ;;
  *)
    printf '%s\n' 'Unsupported operation. No installation or deployment was performed.' >&2
    exit 2
    ;;
esac
