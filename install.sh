#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
case "${1:---plan}" in
  --plan)
    [ "$#" -le 1 ] || { printf '%s\n' 'Unexpected arguments.' >&2; exit 2; }
    printf '%s\n' \
      'dotfiles: reviewed Fedora/Ubuntu CLI installer; deployment disabled by default' \
      "Repository: $repo_root" \
      '1. Review platform, current configuration and installation ownership.' \
      '2. Prepare Git, mise and chezmoi in a separately authorized bootstrap.' \
      '3. Initialize machine data and review a configuration diff.' \
      '4. Prepare selected tool prerequisites, then apply only the separately reviewed migration.' \
      'Use --apply --profile FILE only for a separately reviewed Fedora common or Ubuntu desktop CLI installation.'
    ;;
  --check)
    [ "$#" -eq 1 ] || { printf '%s\n' 'Unexpected arguments.' >&2; exit 2; }
    exec sh "$repo_root/scripts/unix/check.sh"
    ;;
  --apply)
    [ "$#" -eq 3 ] && [ "$2" = '--profile' ] || { printf '%s\n' 'Usage: sh install.sh --apply --profile FILE' >&2; exit 2; }
    command -v python3 >/dev/null 2>&1 || { printf '%s\n' 'Python 3.11+ is required for explicit installation.' >&2; exit 1; }
    exec python3 "$repo_root/scripts/unix/install.py" --profile "$3"
    ;;
  --help|-h)
    printf '%s\n' 'Usage: sh install.sh [--plan|--check|--help] | --apply --profile FILE'
    ;;
  *)
    printf '%s\n' 'Unsupported operation. No installation or deployment was performed.' >&2
    exit 2
    ;;
esac
