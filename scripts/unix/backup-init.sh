#!/bin/sh
# Preserve only the previous chezmoi config before init writes its replacement.
# No package/runtime dependency; dry-run and render destinations never call this.
set -eu
umask 077
case "$1" in "$HOME"/*) ;; *) printf '%s\n' 'Config backup must be inside the actual login home.' >&2; exit 1 ;; esac
[ "$(id -u)" -ne 0 ] || exit 1
[ -f "$1" ] && [ ! -L "$1" ] || { printf '%s\n' 'Config must be a regular file.' >&2; exit 1; }
parent="$HOME/.local/state/dotfiles/init-backups"
mkdir -p "$parent"
chmod 700 "$parent"
backup=$(mktemp -d "$parent/init-XXXXXXXX")
case "$(uname -s)" in
  Darwin) stat -f %Lp "$1" > "$backup/mode.txt" ;;
  Linux) stat -c %a "$1" > "$backup/mode.txt" ;;
  *) printf '%s\n' 'Unsupported config backup platform.' >&2; exit 1 ;;
esac
cp -p -- "$1" "$backup/chezmoi.toml"
chmod 600 "$backup/chezmoi.toml"
