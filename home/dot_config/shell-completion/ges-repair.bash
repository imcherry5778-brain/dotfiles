# Installed GES metadata supplies a bounded fallback when live help stalls.
_list_commands() { builtin printf '%s\n' +clip +test-clip +effect; }
_gst_all_arguments() {
  local help_output
  help_output=$(TERM=dumb NO_COLOR=1 /usr/bin/timeout --kill-after=0.2s 1s "$1" --help-all </dev/null 2>/dev/null)
  if [[ -n $help_output ]]; then
    mapfile -t COMPREPLY < <(printf '%s\n' "$help_output" | sed -nE 'h; s/^  *(-[A-Za-z]),? .*$/\1/p; g; s/^  *(-[A-Za-z], *)?(--[A-Za-z][A-Za-z0-9-]*).*/\2/p' | sort -u | while IFS= read -r option; do [[ $option == "$cur"* ]] && printf '%s\n' "$option"; done)
  elif [[ $1 == ges-launch-1.0 ]]; then
    mapfile -t COMPREPLY < <(compgen -W '-h --help --help-all --help-gst --help-GES --help-project --help-rendering --help-playback --help-informative' -- "$cur")
  else
    COMPREPLY=()
  fi
}
