source "$HOME/.config/shell-completion/query-help.bash"
# The GES provider unconditionally queried live metadata on every Tab.
source /usr/share/bash-completion/completions/ges-launch-1.0
source "$HOME/.config/shell-completion/ges-repair.bash"

# Keep each provider's argument logic, and additionally show its flags at root.
declare -A _SC_ROOT_HANDLER
declare -A _SC_ROOT_NAMES
declare -A _SC_ROOT_ALL_FILES
_sc_root_register_bash() {
  local repair_name=$1 repair_rule repair_handler
  repair_rule=$(complete -p -- "$repair_name" 2>/dev/null)
  if [[ $repair_rule == *' -F '* ]]; then
    repair_handler=${repair_rule#* -F }; repair_handler=${repair_handler%% *}
    if [[ $repair_handler != _sc_root_bash ]]; then
      _SC_ROOT_HANDLER[$repair_name]=$repair_handler
      # complete -p emits a shell-quoted declaration; preserve all its options.
      eval "${repair_rule/ -F $repair_handler / -F _sc_root_bash }"
    fi
  elif [[ -z $repair_rule ]]; then
    complete -o default -F _sc_root_bash -- "$repair_name"
  fi
}
_sc_root_extra_bash() {
  local repair_handler=$1 repair_name=${COMP_WORDS[0]}
  local -a COMP_WORDS=("${COMP_WORDS[@]}")
  local COMP_LINE="${COMP_LINE:0:COMP_POINT}-" COMP_POINT=$((COMP_POINT+1))
  local -a repair_options=()
  local repair_value repair_prefix
  for repair_prefix in '-' '--'; do
    COMP_WORDS[COMP_CWORD]=$repair_prefix
    COMP_LINE="${COMP_LINE:0:${COMP_POINT}-1}$repair_prefix"
    COMP_POINT=${#COMP_LINE}
    "$repair_handler" "$repair_name" "$repair_prefix" "$repair_name"
    for repair_value in "${COMPREPLY[@]}"; do
      [[ $repair_value == -* && $repair_value != - && $repair_value != -- ]] && repair_options+=("$repair_value")
    done
    # Some renderers collapse all long flags to '--' on a single-dash query.
    # Query the full prefix only when that first query returned no flags.
    ((${#repair_options[@]})) && break
  done
  COMPREPLY=("${repair_options[@]}")
}
_sc_root_bash() {
  local repair_name=${COMP_WORDS[0]} repair_handler=${_SC_ROOT_HANDLER[${COMP_WORDS[0]}]-}
  if [[ -z $repair_handler ]]; then
    _comp_load -D -- "$repair_name"
    _sc_root_register_bash "$repair_name"
    repair_handler=${_SC_ROOT_HANDLER[$repair_name]-}
  fi
  if [[ -z $repair_handler || $repair_handler == _sc_root_bash ]]; then
    COMPREPLY=(); return
  fi
  "$repair_handler" "$@"
  if [[ $COMP_CWORD == 1 && -z ${COMP_WORDS[COMP_CWORD]} ]]; then
    local -a repair_root_values=("${COMPREPLY[@]}")
    if [[ ${_SC_ROOT_ALL_FILES[$repair_name]-} == 1 ]]; then
      # Carapace's Bash renderer can return only a common filename prefix.
      # With extra flags that prefix would stop automatic filename expansion.
      mapfile -t repair_root_values < <(compgen -f -- '')
      compopt -o filenames 2>/dev/null
    fi
    _sc_root_extra_bash "$repair_handler"
    COMPREPLY=("${repair_root_values[@]}" "${COMPREPLY[@]}")
    # A flags probe must not leave no-space enabled on ordinary root values.
    compopt +o nospace 2>/dev/null
  fi
  _sc_root_register_bash "$repair_name"
}
source "$HOME/.config/shell-completion/root-options.bash"

# Loading one native file can register several sibling commands and overwrite
# an earlier root wrapper. Reapply wrappers after every normal lazy load.
_sc_refresh_root_bash() {
  local repair_rule repair_handler repair_name
  while IFS= read -r repair_rule; do
    [[ $repair_rule == *' -F '* ]] || continue
    repair_name=${repair_rule##* }
    [[ -n ${_SC_ROOT_NAMES[$repair_name]-} ]] || continue
    repair_handler=${repair_rule#* -F }; repair_handler=${repair_handler%% *}
    if [[ $repair_handler != _sc_root_bash ]]; then
      _SC_ROOT_HANDLER[$repair_name]=$repair_handler
      eval "${repair_rule/ -F $repair_handler / -F _sc_root_bash }"
    fi
  done < <(complete -p)
}
if [[ ! ${_SC_LOAD_REPAIRED-} ]]; then
  _SC_LOAD_REPAIRED=1
  eval "$(declare -f _comp_load | sed '1s/_comp_load/_sc_load_original/')"
  _comp_load() {
    _sc_load_original "$@"
    local repair_load_status=$?
    _sc_refresh_root_bash
    return "$repair_load_status"
  }
fi
