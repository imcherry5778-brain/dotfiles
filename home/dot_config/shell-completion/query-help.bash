# Only completion's help queries use plain output and a bounded runtime.
if [[ ! ${_SC_HELP_REPAIRED-} && $(type -t _comp_compgen_help__get_help_lines) == function ]]; then
  _SC_HELP_REPAIRED=1
  eval "$(declare -f _comp_compgen_help__get_help_lines | sed '1s/_comp_compgen_help__get_help_lines/_sc_get_help_original/')"
  _comp_compgen_help__get_help_lines() {
    local query_command
    case ${1-} in
      -) TERM=dumb NO_COLOR=1 _sc_get_help_original "$@" ;;
      -c)
        case $(type -t -- "${2-}") in
          builtin|function) TERM=dumb NO_COLOR=1 _sc_get_help_original "$@" ;;
          *) TERM=dumb NO_COLOR=1 _sc_get_help_original -c /usr/bin/timeout --kill-after=0.2s 1s "${@:2}" ;;
        esac
        ;;
      *)
        [[ ${1-} == -- ]] && shift
        local REPLY
        _comp_dequote "${comp_args[0]-}"
        query_command=${REPLY:-false}
        # The installed vpnc manual documents these flags; no VPN invocation.
        if [[ ${query_command##*/} == vpnc && ${1-} == --long-help ]]; then
          mapfile -t _lines < "$HOME/.config/shell-completion/vpnc-help.txt"
          return 0
        fi
        TERM=dumb NO_COLOR=1 _sc_get_help_original -c /usr/bin/timeout --kill-after=0.2s 1s "$query_command" "$@"
        local query_status=$?
        # Native parsing prefers a long alias. Preserve the short options that
        # id/mktemp previously exposed via their POSIX fallback too.
        if ((query_status == 0)) && [[ ${query_command##*/} == id || ${query_command##*/} == mktemp ]]; then
          local query_line
          local -a query_shorts=()
          for query_line in "${_lines[@]}"; do
            [[ $query_line =~ ^[[:blank:]]+(-[A-Za-z0-9?])([[:blank:]]|,) ]] && query_shorts+=("  ${BASH_REMATCH[1]}")
          done
          _lines+=("${query_shorts[@]}")
        fi
        return "$query_status"
        ;;
    esac
  }
fi
