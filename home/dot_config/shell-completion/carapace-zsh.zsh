function _sc_carapace_base {
  local command="${words[1]:t}"
  command=${_SC_CARAPACE_BACKEND[$command]:-$command}
  local compline=${words[@]:0:$CURRENT}
  local IFS=$'\n'
  local lines

  declare -x CARAPACE_COMPLINE="${words}"
  declare -x CARAPACE_ZSH_HASH_DIRS="$(hash -d)"
  declare -x CARAPACE_SHELL=zsh
  declare -x CARAPACE_SHELL_ALIASES="${(k)aliases}"
  declare -x CARAPACE_SHELL_BUILTINS="$(print -roC1 -- ${(k)builtins})"
  declare -x CARAPACE_SHELL_FUNCTIONS="$(print -l ${(ok)functions})"
  declare -x CARAPACE_SHELL_JOBS="$(print -l ${${(k)jobtexts}/#/%%})"
  declare -x CARAPACE_SHELL_VARIABLES="$(print -l ${(ok)parameters})"

  local -a arguments=("${words[@]:0:$CURRENT}")
  arguments[-1]="$PREFIX"
  [[ ${_SC_OPTIONS_QUERY-} == 1 ]] && arguments[-1]='-'
  local -a quoted=("${(@q)arguments}")
  [[ -z $arguments[-1] ]] && quoted[-1]=''
  declare -x SC_BASH_WORDS="${(j::)arguments}"
  declare -x SC_BASH_LINE="${(j: :)quoted}"
  lines="$(command carapace "$command" zsh "${arguments[@]}" 2>/dev/null)"

  local zstyle message noprefix data
  IFS=$'\001' read -r -d '' zstyle message noprefix data <<<"${lines}"
  # shellcheck disable=SC2154
  zstyle ":completion:${curcontext}:*" list-colors "${zstyle}"
  zstyle ":completion:${curcontext}:*" group-name ''
  [ -z "$message" ] || _message -r "${message}"
  [[ "${noprefix}" = "true" ]] && compstate[insert]=menu

  local block tag displays values displaysArr valuesArr
  while IFS=$'\002' read -r -d $'\002' block; do
    IFS=$'\003' read -r -d '' tag displays values <<<"${block}"
    # shellcheck disable=SC2034
    IFS=$'\n' read -r -d $'\004' -A displaysArr <<<"${displays}"$'\004'
    IFS=$'\n' read -r -d $'\004' -A valuesArr <<<"${values}"$'\004'

    if [[ ${_SC_OPTIONS_QUERY-} == 1 ]]; then
      local -a kept_values kept_displays
      local -i option_index
      kept_values=(); kept_displays=()
      for (( option_index=1; option_index<=${#valuesArr}; option_index++ )); do
        if [[ $valuesArr[option_index] == -* && $valuesArr[option_index] != - && $valuesArr[option_index] != -- ]]; then
          kept_values+=("$valuesArr[option_index]")
          kept_displays+=("$displaysArr[option_index]")
        fi
      done
      valuesArr=("$kept_values[@]"); displaysArr=("$kept_displays[@]")
    fi
    [[ ${#valuesArr[@]} -gt 1 ]] && _describe -t "${tag}" "${tag}" displaysArr valuesArr -Q -S ''
  done <<<"${data}"
}
