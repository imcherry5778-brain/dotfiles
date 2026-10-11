# Selected providers; no full Carapace initialization.
[[ -n ${_SC_BASH_INITIALIZED-} ]] && return
_SC_BASH_INITIALIZED=1
# PATH is owned by .bashrc.
declare -A _SC_BASH_PATH _SC_BASH_HANDLER
_sc_native_bash() {
  local command=${COMP_WORDS[0]} directory registration function_name
  [[ $command == cloudflare ]] && command=cf
  if [[ ${_SC_BASH_PWD-} != "$PWD" ]]; then _SC_BASH_PATH=(); _SC_BASH_PWD=$PWD; fi
  directory=${_SC_BASH_PATH[$command]}
  if [[ -z $directory ]]; then
    directory=$("$HOME/.local/bin/refresh-completions" --resolve "$command") || return 1
    source "$directory/completion.bash"
    registration=$(complete -p "$command")
    local -a tokens
    read -ra tokens <<< "$registration"
    local i
    for ((i=0;i<${#tokens[@]};i++)); do
      [[ ${tokens[i]} == -F ]] && function_name=${tokens[i+1]}
    done
    _SC_BASH_PATH[$command]=$directory
    _SC_BASH_HANDLER[$command]=$function_name
    complete -o default -F _sc_native_bash "$command"
    [[ $command == cf ]] && complete -o default -F _sc_native_bash cloudflare
  fi
  "${_SC_BASH_HANDLER[$command]}" "$@"
}
source "$HOME/.config/shell-completion/carapace-bash.bash"
complete -o default -F _sc_native_bash ai-cli
complete -o default -F _sc_native_bash argocd
complete -o default -F _sc_native_bash cf
complete -o default -F _sc_native_bash cloudflare
complete -o default -F _sc_native_bash codex
complete -o default -F _sc_native_bash ffplay
complete -o default -F _sc_native_bash ffprobe
complete -o default -F _sc_native_bash lazygit
complete -o default -F _sc_native_bash magick
complete -o default -F _sc_native_bash trash
complete -o default -F _sc_native_bash trash-empty
complete -o default -F _sc_native_bash trash-list
complete -o default -F _sc_native_bash trash-put
complete -o default -F _sc_native_bash trash-restore
complete -o default -F _sc_native_bash ya
complete -o default -F _sc_native_bash yazi
complete -o default -F _sc_carapace_bash acpid
complete -o default -F _sc_carapace_bash agy
complete -o default -F _sc_carapace_bash alsamixer
complete -o default -F _sc_carapace_bash aplay
complete -o default -F _sc_carapace_bash ar
complete -o default -F _sc_carapace_bash arecord
complete -o default -F _sc_carapace_bash awk
complete -o default -F _sc_carapace_bash baobab
complete -o default -F _sc_carapace_bash base32
complete -o default -F _sc_carapace_bash base64
complete -o default -F _sc_carapace_bash basename
complete -o default -F _sc_carapace_bash bash
complete -o default -F _sc_carapace_bash bc
complete -o default -F _sc_carapace_bash bluetoothctl
complete -o default -F _sc_carapace_bash brotli
complete -o default -F _sc_carapace_bash cargo-clippy
complete -o default -F _sc_carapace_bash cargo-fmt
complete -o default -F _sc_carapace_bash cat
complete -o default -F _sc_carapace_bash chroot
complete -o default -F _sc_carapace_bash comm
complete -o default -F _sc_carapace_bash cp
complete -o default -F _sc_carapace_bash csplit
complete -o default -F _sc_carapace_bash cut
complete -o default -F _sc_carapace_bash date
complete -o default -F _sc_carapace_bash dc
complete -o default -F _sc_carapace_bash df
complete -o default -F _sc_carapace_bash diff
complete -o default -F _sc_carapace_bash diff3
complete -o default -F _sc_carapace_bash dir
complete -o default -F _sc_carapace_bash dircolors
complete -o default -F _sc_carapace_bash dirname
complete -o default -F _sc_carapace_bash dnsmasq
complete -o default -F _sc_carapace_bash dockerd
complete -o default -F _sc_carapace_bash dos2unix
complete -o default -F _sc_carapace_bash du
complete -o default -F _sc_carapace_bash egrep
complete -o default -F _sc_carapace_bash envsubst
complete -o default -F _sc_carapace_bash expand
complete -o default -F _sc_carapace_bash expr
complete -o default -F _sc_carapace_bash factor
complete -o default -F _sc_carapace_bash fc-cache
complete -o default -F _sc_carapace_bash fc-cat
complete -o default -F _sc_carapace_bash fc-conflist
complete -o default -F _sc_carapace_bash fc-list
complete -o default -F _sc_carapace_bash ffmpeg
complete -o default -F _sc_carapace_bash fgrep
complete -o default -F _sc_carapace_bash fmt
complete -o default -F _sc_carapace_bash fold
complete -o default -F _sc_carapace_bash fzf
complete -o default -F _sc_carapace_bash gnome-keyring
complete -o default -F _sc_carapace_bash gnome-keyring-daemon
complete -o default -F _sc_carapace_bash gnome-maps
complete -o default -F _sc_carapace_bash go
complete -o default -F _sc_carapace_bash gofmt
complete -o default -F _sc_carapace_bash gpg-agent
complete -o default -F _sc_carapace_bash grep
complete -o default -F _sc_carapace_bash groups
complete -o default -F _sc_carapace_bash gunzip
complete -o default -F _sc_carapace_bash halt
complete -o default -F _sc_carapace_bash head
complete -o default -F _sc_carapace_bash hostid
complete -o default -F _sc_carapace_bash hugetop
complete -o default -F _sc_carapace_bash install
complete -o default -F _sc_carapace_bash join
complete -o default -F _sc_carapace_bash keytool
complete -o default -F _sc_carapace_bash link
complete -o default -F _sc_carapace_bash ln
complete -o default -F _sc_carapace_bash locale
complete -o default -F _sc_carapace_bash logname
complete -o default -F _sc_carapace_bash ls
complete -o default -F _sc_carapace_bash mitmproxy
complete -o default -F _sc_carapace_bash mkcert
complete -o default -F _sc_carapace_bash mkdir
complete -o default -F _sc_carapace_bash mkfifo
complete -o default -F _sc_carapace_bash mknod
complete -o default -F _sc_carapace_bash mv
complete -o default -F _sc_carapace_bash nano
complete -o default -F _sc_carapace_bash nice
complete -o default -F _sc_carapace_bash nl
complete -o default -F _sc_carapace_bash node
complete -o default -F _sc_carapace_bash nohup
complete -o default -F _sc_carapace_bash numfmt
complete -o default -F _sc_carapace_bash nvim
complete -o default -F _sc_carapace_bash od
complete -o default -F _sc_carapace_bash ollama
complete -o default -F _sc_carapace_bash paste
complete -o default -F _sc_carapace_bash pathchk
complete -o default -F _sc_carapace_bash pdfattach
complete -o default -F _sc_carapace_bash pdfdetach
complete -o default -F _sc_carapace_bash pdffonts
complete -o default -F _sc_carapace_bash pdfimages
complete -o default -F _sc_carapace_bash pdfinfo
complete -o default -F _sc_carapace_bash pdfseparate
complete -o default -F _sc_carapace_bash pdfsig
complete -o default -F _sc_carapace_bash pdftocairo
complete -o default -F _sc_carapace_bash pdftohtml
complete -o default -F _sc_carapace_bash pdftops
complete -o default -F _sc_carapace_bash pdfunite
complete -o default -F _sc_carapace_bash pidwait
complete -o default -F _sc_carapace_bash pinky
complete -o default -F _sc_carapace_bash pmap
complete -o default -F _sc_carapace_bash pnpm
complete -o default -F _sc_carapace_bash poweroff
complete -o default -F _sc_carapace_bash pr
complete -o default -F _sc_carapace_bash ptx
complete -o default -F _sc_carapace_bash qemu-img
complete -o default -F _sc_carapace_bash qemu-io
complete -o default -F _sc_carapace_bash qemu-nbd
complete -o default -F _sc_carapace_bash qemu-pr-helper
complete -o default -F _sc_carapace_bash qemu-storage-daemon
complete -o default -F _sc_carapace_bash qemu-vmsr-helper
complete -o default -F _sc_carapace_bash qrencode
complete -o default -F _sc_carapace_bash readlink
complete -o default -F _sc_carapace_bash reboot
complete -o default -F _sc_carapace_bash rm
complete -o default -F _sc_carapace_bash rmdir
complete -o default -F _sc_carapace_bash rust-analyzer
complete -o default -F _sc_carapace_bash rustc
complete -o default -F _sc_carapace_bash rustdoc
complete -o default -F _sc_carapace_bash sed
complete -o default -F _sc_carapace_bash seq
complete -o default -F _sc_carapace_bash showkey
complete -o default -F _sc_carapace_bash shred
complete -o default -F _sc_carapace_bash shutdown
complete -o default -F _sc_carapace_bash sleep
complete -o default -F _sc_carapace_bash sort
complete -o default -F _sc_carapace_bash split
complete -o default -F _sc_carapace_bash ssh-agent
complete -o default -F _sc_carapace_bash stat
complete -o default -F _sc_carapace_bash stty
complete -o default -F _sc_carapace_bash sudoreplay
complete -o default -F _sc_carapace_bash sulogin
complete -o default -F _sc_carapace_bash sum
complete -o default -F _sc_carapace_bash sync
complete -o default -F _sc_carapace_bash tac
complete -o default -F _sc_carapace_bash tail
complete -o default -F _sc_carapace_bash tailscale
complete -o default -F _sc_carapace_bash tee
complete -o default -F _sc_carapace_bash tload
complete -o default -F _sc_carapace_bash tmate
complete -o default -F _sc_carapace_bash top
complete -o default -F _sc_carapace_bash touch
complete -o default -F _sc_carapace_bash tr
complete -o default -F _sc_carapace_bash tsh
complete -o default -F _sc_carapace_bash tsort
complete -o default -F _sc_carapace_bash tty
complete -o default -F _sc_carapace_bash uname
complete -o default -F _sc_carapace_bash unexpand
complete -o default -F _sc_carapace_bash uniq
complete -o default -F _sc_carapace_bash unlink
complete -o default -F _sc_carapace_bash unxz
complete -o default -F _sc_carapace_bash unzip
complete -o default -F _sc_carapace_bash upower
complete -o default -F _sc_carapace_bash uptime
complete -o default -F _sc_carapace_bash users
complete -o default -F _sc_carapace_bash vagrant
complete -o default -F _sc_carapace_bash vdir
complete -o default -F _sc_carapace_bash vi
complete -o default -F _sc_carapace_bash visudo
complete -o default -F _sc_carapace_bash vlc
complete -o default -F _sc_carapace_bash w
complete -o default -F _sc_carapace_bash wc
complete -o default -F _sc_carapace_bash which
complete -o default -F _sc_carapace_bash who
complete -o default -F _sc_carapace_bash whoami
complete -o default -F _sc_carapace_bash wireshark
complete -o default -F _sc_carapace_bash xargs
complete -o default -F _sc_carapace_bash xclip
complete -o default -F _sc_carapace_bash xzcat
complete -o default -F _sc_carapace_bash yes
complete -o default -F _sc_carapace_bash zcat
complete -o default -F _sc_carapace_bash zip
complete -o default -F _sc_carapace_bash zoxide
source "$HOME/.config/shell-completion/argcomplete.zsh"
complete -o nospace -o default -F _python_argcomplete az
complete -o nospace -o default -F _python_argcomplete pipx
complete -o nospace -o default -F _python_argcomplete abrt
complete -o nospace -o default -F _python_argcomplete abrt-cli
complete -o nospace -o default -F _python_argcomplete rpmdev-spectool

_sc_mamba_bash() { mapfile -t COMPREPLY < <("$HOME/miniforge3/bin/mamba" completer "${COMP_WORDS[@]:1}"); }
complete -o default -F _sc_mamba_bash mamba
complete -o default -F _sc_carapace_bash carapace
refresh-completions() {
  command "$HOME/.local/bin/refresh-completions" "$@" || return
  _SC_BASH_PATH=()
}
_sc_refresh_completions_bash() {
  local choices='codex gh uv uvx k9s lazygit k6 argocd cosign oras rustup cf bw trash trash-put trash-list trash-empty trash-restore ai-cli yazi ya cargo ffplay ffprobe magick compare'
  [[ ${COMP_WORDS[COMP_CWORD]} == -* ]] && choices='--help --force --resolve'
  mapfile -t COMPREPLY < <(compgen -W "$choices" -- "${COMP_WORDS[COMP_CWORD]}")
}
complete -o default -F _sc_refresh_completions_bash refresh-completions
source "$HOME/.config/shell-completion/wall.bash"

source "$HOME/.config/shell-completion/repairs.bash"
