# Loaded before Oh My Zsh's compinit.
typeset -g SC_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/shell-completion"
fpath=("$SC_DATA/zsh/native" "$SC_DATA/zsh/community" $fpath)
# PATH is owned by .zshrc; do not prepend the same directory again here.
