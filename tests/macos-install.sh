#!/bin/sh
set -eu
[ "${GITHUB_ACTIONS:-}" = true ] && [ "${RUNNER_ENVIRONMENT:-}" = github-hosted ] || { printf '%s\n' 'Hosted disposable CI only.' >&2; exit 1; }
[ "$(uname -m)" = arm64 ] || exit 1
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
[ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ] || exit 1
printf '\n[acceptance]\n keep = existing\n' >> "$HOME/.gitconfig"
printf '\n# Existing login customization\nexport RETAINED_MAC_LOGIN=yes\n' >> "$HOME/.zprofile"
sh "$repo/install.sh" --apply
zsh -lic '
set -e
[[ $RETAINED_MAC_LOGIN == yes ]]
[[ $ZSH_THEME == robbyrussell && $EDITOR == nvim ]]
[[ $(command -v node) == $HOME/.local/share/mise/installs/* ]]
[[ $(printf "%s\n" $path | sort | uniq -d) == "" ]]
(( $+functions[__zoxide_z] && $+widgets[fzf-history-widget] && $+functions[_sc_carapace_base] ))
[[ $(git config --get acceptance.keep) == existing ]]
nvim --headless -u NONE -i NONE "+lua assert(vim.fn.has(\"mac\") == 1)" +qa
'
chezmoi --no-tty --no-pager apply
fd_binary=$(mise which fd)
rm -- "$fd_binary"
chezmoi --no-tty --no-pager apply
[ -f "$fd_binary" ]
chezmoi --no-tty --no-pager verify --exclude=scripts
[ -z "$(chezmoi --no-tty --no-pager diff --exclude=scripts)" ]
printf '%s\n' 'Mac ARM64: installation, CLI execution, login/completion and repeat apply passed. Personal GUI/authentication excluded.'
