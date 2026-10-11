#!/bin/sh
# Runtime bootstrap only; sourced by the explicit installer and disposable CI.
# Never source user shell startup files to discover tools.
bootstrap_at_least() {
  # Numeric comparison: lexicographic sort would treat 2026.9 as newer than 2026.10.
  awk -v actual="$1" -v required="$2" 'BEGIN {
    split(actual, a, "."); split(required, b, ".")
    for (i=1; i<=3; i++) { if (a[i]+0 > b[i]+0) exit 0; if (a[i]+0 < b[i]+0) exit 1 }
    exit 0
  }'
}

bootstrap_runtime() {
  bootstrap_repo=$1
  [ "$(id -u)" -ne 0 ] || { printf '%s\n' 'Run the installer as your regular desktop user.' >&2; return 1; }
  for bootstrap_key in XDG_CONFIG_HOME XDG_DATA_HOME MISE_CONFIG_DIR MISE_DATA_DIR MISE_GLOBAL_CONFIG_FILE; do
    eval 'bootstrap_value=${'"$bootstrap_key"'-}'
    [ -z "$bootstrap_value" ] || { printf '%s\n' "$bootstrap_key redirects the environment; review it first." >&2; return 1; }
  done
  case "$(uname -s):$(uname -m)" in
    Darwin:arm64)
      # Suppress Homebrew periodic whole-install cleanup in this process only.
      export HOMEBREW_NO_INSTALL_CLEANUP=1
      [ -x /opt/homebrew/bin/brew ] || {
        xcode-select -p >/dev/null 2>&1 || { xcode-select --install; printf '%s\n' 'Complete Apple Command Line Tools installation, then repeat this command.' >&2; return 1; }
        bootstrap_download=$(mktemp)
        curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/7a3f48c7e498d7df3237fd41c30f4d492857edf4/install.sh' -o "$bootstrap_download" || { rm -f "$bootstrap_download"; return 1; }
        [ "$(shasum -a 256 "$bootstrap_download" | awk '{print $1}')" = '5f333bbe53bc490e51e7ccb1df8779b3dd6ee73a1a7379efda216edb08ccb148' ] || { rm -f "$bootstrap_download"; printf '%s\n' 'Homebrew installer checksum mismatch.' >&2; return 1; }
        /bin/bash "$bootstrap_download"
        bootstrap_status=$?
        rm -f "$bootstrap_download"
        [ "$bootstrap_status" -eq 0 ] || return "$bootstrap_status"
      }
      PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$PATH"
      export PATH
      bootstrap_refresh=0
      bootstrap_version=$(cd "$HOME" && mise --version 2>/dev/null | awk '{print $1}') || bootstrap_version=0.0.0
      bootstrap_chezmoi_version=$(chezmoi --version 2>/dev/null | sed -n 's/.*version v*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p') || bootstrap_chezmoi_version=0.0.0
      if ! bootstrap_at_least "${bootstrap_version:-0.0.0}" 2026.10.3; then bootstrap_refresh=1; fi
      if ! bootstrap_at_least "${bootstrap_chezmoi_version:-0.0.0}" 2.73.0; then bootstrap_refresh=1; fi
      # Hosted images can disable auto-update. Refresh metadata, not installed packages.
      if [ "$bootstrap_refresh" -eq 1 ]; then brew update; fi
      for bootstrap_tool in mise chezmoi; do
        if ! command -v "$bootstrap_tool" >/dev/null 2>&1; then
          brew install "$bootstrap_tool"
        elif [ "$bootstrap_tool" = mise ] && ! bootstrap_at_least "${bootstrap_version:-0.0.0}" 2026.10.3; then
          brew upgrade mise
        elif [ "$bootstrap_tool" = chezmoi ] && ! bootstrap_at_least "${bootstrap_chezmoi_version:-0.0.0}" 2.73.0; then
          brew upgrade chezmoi
        fi
      done
      ;;
    Linux:x86_64)
      . /etc/os-release
      case "$ID" in fedora|ubuntu|arch|opensuse-tumbleweed) ;; *) printf '%s\n' "Unsupported Linux: $ID" >&2; return 1 ;; esac
      if [ "$ID" = ubuntu ] && [ "$VERSION_ID" != 26.04 ]; then printf '%s\n' 'Ubuntu 26.04 is required.' >&2; return 1; fi
      PATH="$HOME/.local/bin:$PATH"; export PATH
      if ! command -v curl >/dev/null 2>&1; then
        command -v sudo >/dev/null 2>&1 || { printf '%s\n' 'Install curl and ca-certificates, or provide sudo for OS prerequisites.' >&2; return 1; }
        case "$ID" in
          ubuntu) sudo apt-get update; sudo apt-get install -y --no-remove curl ca-certificates ;;
          fedora) sudo dnf install -y curl ca-certificates ;;
          arch)
            ls /var/lib/pacman/sync/*.db >/dev/null 2>&1 || { printf '%s\n' 'Run a full pacman -Syu first; never -Sy alone.' >&2; return 1; }
            sudo pacman -S --needed --noconfirm curl ca-certificates ;;
          opensuse-tumbleweed) sudo zypper --non-interactive install --no-recommends curl ca-certificates ;;
        esac
      fi
      if ! command -v mise >/dev/null 2>&1; then
        bootstrap_metadata="$bootstrap_repo/scripts/mise-release.json"
        bootstrap_version=$(sed -n 's/.*"version": "\([^"]*\)".*/\1/p' "$bootstrap_metadata")
        bootstrap_sha=$(sed -n '/"linux-amd64"/,/}/{s/.*"sha256": "\([^"]*\)".*/\1/p;}' "$bootstrap_metadata")
        bootstrap_asset=$(sed -n '/"linux-amd64"/,/}/{s/.*"name": "\([^"]*\)".*/\1/p;}' "$bootstrap_metadata")
        [ ! -e "$HOME/.local/bin/mise" ] && [ ! -L "$HOME/.local/bin/mise" ] || { printf '%s\n' 'Unresolved mise path exists; refusing to overwrite.' >&2; return 1; }
        mkdir -p "$HOME/.local/bin"
        bootstrap_download=$(mktemp)
        curl -fsSL "https://github.com/jdx/mise/releases/download/v$bootstrap_version/$bootstrap_asset" -o "$bootstrap_download" || { rm -f "$bootstrap_download"; return 1; }
        [ "$(sha256sum "$bootstrap_download" | awk '{print $1}')" = "$bootstrap_sha" ] || { rm -f "$bootstrap_download"; printf '%s\n' 'mise checksum mismatch.' >&2; return 1; }
        chmod 755 "$bootstrap_download"
        mv "$bootstrap_download" "$HOME/.local/bin/mise"
      fi
      ;;
    *) printf '%s\n' 'Supported: Linux x86_64 or Apple Silicon macOS.' >&2; return 1 ;;
  esac
  bootstrap_mise=$(command -v mise)
  "$bootstrap_mise" trust "$bootstrap_repo/mise.toml"
  "$bootstrap_mise" trust "$bootstrap_repo/scripts/unix/mise.toml"
  "$bootstrap_mise" -C "$bootstrap_repo/scripts/unix" install python --yes
}
