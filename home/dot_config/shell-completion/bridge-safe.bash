# Called after Carapace reloads the completion library and selected provider.
source "$HOME/.config/shell-completion/query-help.bash"
if [[ ${COMP_WORDS[0]} == ges-launch-1.0 ]]; then
  source "$HOME/.config/shell-completion/ges-repair.bash"
fi
registration=$(complete -p -- "${COMP_WORDS[0]}" 2>/dev/null)
if [[ $registration == *' -F '* ]]; then
  _SC_BRIDGE_CALLBACK=${registration#* -F }
  _SC_BRIDGE_CALLBACK=${_SC_BRIDGE_CALLBACK%% *}
  _sc_bridge_callback() {
    "$_SC_BRIDGE_CALLBACK" "${COMP_WORDS[0]}" "${COMP_WORDS[COMP_CWORD]}" "${COMP_WORDS[COMP_CWORD-1]}"
    # The provider is finished. Only the bridge's final string output remains.
    # Its echo loop must preserve literal -n/-e/-E and backslashes.
    echo() { builtin printf '%s\n' "$@"; }
  }
  complete -F _sc_bridge_callback -- "${COMP_WORDS[0]}"
fi
