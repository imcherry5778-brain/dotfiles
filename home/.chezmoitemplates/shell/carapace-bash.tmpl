_sc_carapace_bash() {
  export COMP_LINE
  export COMP_POINT
  export COMP_TYPE
  export COMP_WORDBREAKS

  declare -x CARAPACE_SHELL=bash
  declare -x CARAPACE_SHELL_ALIASES="$(compgen -a)"
  declare -x CARAPACE_SHELL_BUILTINS="$(compgen -b)"
  declare -x CARAPACE_SHELL_FUNCTIONS="$(compgen -A function)"
  declare -x CARAPACE_SHELL_JOBS="$(jobs 2>/dev/null | while read -r line; do [[ $line =~ \[([0-9]+)\] ]] && echo "%${BASH_REMATCH[1]}"; done)"
  declare -x CARAPACE_SHELL_VARIABLES="$(compgen -v)"

  local command="${COMP_WORDS[0]}" nospace data compline="${COMP_LINE:0:${COMP_POINT}}"

  local -a arguments=("${COMP_WORDS[@]:0:$((COMP_CWORD+1))}")
  data=$(command carapace "$command" bash "${arguments[@]}" 2>/dev/null)

  IFS=$'\001' read -r -d '' nospace data <<<"${data}"
  mapfile -t COMPREPLY < <(printf '%s\n' "${data}")
  unset COMPREPLY[-1]

  [ "${nospace}" = true ] && compopt -o nospace
  local IFS=$'\n'
  [[ "${COMPREPLY[*]}" == "" ]] && COMPREPLY=() # fix for mapfile creating a non-empty array from empty command output
}
