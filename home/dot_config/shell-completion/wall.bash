# Keep the installed provider's files/groups; expose options at an empty prompt.
source /usr/share/bash-completion/completions/wall
_sc_wall_bash() {
  local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}
  local options='-g --group -n --nobanner -t --timeout -h --help -V --version'
  _wall_module "$@"
  case $prev in
    -t|--timeout) COMPREPLY=(); return ;;
    -g|--group) return ;;
  esac
  if [[ $cur == -* ]]; then
    mapfile -t COMPREPLY < <(compgen -W "$options" -- "$cur")
  elif [[ $COMP_CWORD == 1 && -z $cur ]]; then
    local -a flags
    read -ra flags <<< "$options"
    COMPREPLY+=("${flags[@]}")
  fi

}
complete -F _sc_wall_bash wall
