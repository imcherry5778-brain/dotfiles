# Loaded after existing conda/mamba hooks.
[[ -n ${_SC_INITIALIZED-} ]] && return
typeset -g _SC_INITIALIZED=1
typeset -gA _SC_NATIVE_PATH _SC_NATIVE_LOADED _SC_NATIVE_FUNCTIONS
_sc_native_context() { _SC_NATIVE_PATH=(); }
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _sc_native_context
_sc_native() {
  local command=$1 main=$2 directory old
  shift 2
  directory=${_SC_NATIVE_PATH[$command]}
  if [[ -z $directory ]]; then
    directory=$("$HOME/.local/bin/refresh-completions" --resolve "$command") || return 1
    _SC_NATIVE_PATH[$command]=$directory
  fi
  if [[ ${_SC_NATIVE_LOADED[$command]} != $directory ]]; then
    old=${_SC_NATIVE_LOADED[$command]}
    [[ -n $old ]] && fpath=(${fpath:#$old})
    local function_name
    for function_name in ${=_SC_NATIVE_FUNCTIONS[$command]} $main; do
      unfunction "$function_name" 2>/dev/null
    done
    fpath=("$directory" $fpath)
    _SC_NATIVE_FUNCTIONS[$command]=$(<"$directory/functions")
    autoload -Uz "$main"
    _SC_NATIVE_LOADED[$command]=$directory
  fi
  "$main" "$@"
}
source "$HOME/.config/shell-completion/carapace-zsh.zsh"
typeset -gA _SC_CARAPACE_BACKEND=(
  fsck.cramfs scbridge_fsck_cramfs
  fsck.minix scbridge_fsck_minix
  ges-launch-1.0 scbridge_ges_launch_1_0
  gst-inspect-1.0 scbridge_gst_inspect_1_0
  gst-launch-1.0 scbridge_gst_launch_1_0
  mkfs.cramfs scbridge_mkfs_cramfs
  mkfs.minix scbridge_mkfs_minix
)

source "$HOME/.config/shell-completion/argcomplete.zsh"
compdef _python_argcomplete az pipx abrt abrt-cli gdctl spectool rpmdev-spectool
if (( $+functions[_umamba_zsh_completions] )); then
  complete -o default -F _umamba_zsh_completions mamba
fi
compdef _sc_carapace 7z
compdef _sc_carapace acpid
compdef _sc_carapace agy
compdef _sc_carapace alsamixer
compdef _sc_carapace ar
compdef _sc_carapace autoconf
compdef _sc_carapace baobab
compdef _sc_carapace bc
compdef _sc_carapace brotli
compdef _sc_carapace cargo-clippy
compdef _sc_carapace cargo-fmt
compdef _sc_carapace cfdisk
compdef _sc_carapace compare
compdef _sc_carapace conda
compdef _sc_carapace dc
compdef _sc_carapace dir
compdef _sc_carapace dircolors
compdef _sc_carapace dirname
compdef _sc_carapace dnsmasq
compdef _sc_carapace dockerd
compdef _sc_carapace envsubst
compdef _sc_carapace expr
compdef _sc_carapace factor
compdef _sc_carapace fc-cache
compdef _sc_carapace fc-cat
compdef _sc_carapace fc-conflist
compdef _sc_carapace fdisk
compdef _sc_carapace ffplay
compdef _sc_carapace ffprobe
compdef _sc_carapace file
compdef _sc_carapace fzf
compdef _sc_carapace gnome-keyring
compdef _sc_carapace gnome-keyring-daemon
compdef _sc_carapace gnome-maps
compdef _sc_carapace google-chrome
compdef _sc_carapace gpg-agent
compdef _sc_carapace groupmems
compdef _sc_carapace halt
compdef _sc_carapace hostid
compdef _sc_carapace hugetop
compdef _sc_carapace hunspell
compdef _sc_carapace k3d
compdef _sc_carapace link
compdef _sc_carapace lsclocks
compdef _sc_carapace lsfd
compdef _sc_carapace lsirq
compdef _sc_carapace magick
compdef _sc_carapace mitmproxy
compdef _sc_carapace mkfs
compdef _sc_carapace mkswap
compdef _sc_carapace more
compdef _sc_carapace nproc
compdef _sc_carapace ollama
compdef _sc_carapace packer
compdef _sc_carapace pathchk
compdef _sc_carapace pdfattach
compdef _sc_carapace pdfdetach
compdef _sc_carapace pdfseparate
compdef _sc_carapace pdfsig
compdef _sc_carapace pdftocairo
compdef _sc_carapace pdftohtml
compdef _sc_carapace pdfunite
compdef _sc_carapace pidwait
compdef _sc_carapace pinky
compdef _sc_carapace pipx
compdef _sc_carapace pnpm
compdef _sc_carapace poweroff
compdef _sc_carapace pwd
compdef _sc_carapace qemu-img
compdef _sc_carapace qemu-io
compdef _sc_carapace qemu-nbd
compdef _sc_carapace qemu-pr-helper
compdef _sc_carapace qemu-storage-daemon
compdef _sc_carapace qemu-vmsr-helper
compdef _sc_carapace qrencode
compdef _sc_carapace reboot
compdef _sc_carapace rename
compdef _sc_carapace rust-analyzer
compdef _sc_carapace rustc
compdef _sc_carapace rustdoc
compdef _sc_carapace scriptlive
compdef _sc_carapace showkey
compdef _sc_carapace sleep
compdef _sc_carapace sudoreplay
compdef _sc_carapace sulogin
compdef _sc_carapace tailscale
compdef _sc_carapace terraform
compdef _sc_carapace tmate
compdef _sc_carapace tofu
compdef _sc_carapace tsh
compdef _sc_carapace tshark
compdef _sc_carapace tsort
compdef _sc_carapace unlink
compdef _sc_carapace users
compdef _sc_carapace vagrant
compdef _sc_carapace vault
compdef _sc_carapace vdir
compdef _sc_carapace vlc
compdef _sc_carapace wg
compdef _sc_carapace wireshark
compdef _sc_carapace yes
compdef _sc_carapace zoxide
compdef _sc_carapace aclocal
compdef _sc_carapace addpart
compdef _sc_carapace alternatives
compdef _sc_carapace appstreamcli
compdef _sc_carapace auditctl
compdef _sc_carapace augenrules
compdef _sc_carapace aureport
compdef _sc_carapace ausearch
compdef _sc_carapace authselect
compdef _sc_carapace autoheader
compdef _sc_carapace automake
compdef _sc_carapace autoreconf
compdef _sc_carapace autoscan
compdef _sc_carapace autoupdate
compdef _sc_carapace badblocks
compdef _sc_carapace biosdecode
compdef _sc_carapace bits
compdef _sc_carapace blkdiscard
compdef _sc_carapace blkpr
compdef _sc_carapace blkzone
compdef _sc_carapace blockdev
compdef _sc_carapace cancel
compdef _sc_carapace cardos-tool
compdef _sc_carapace chronyc
compdef _sc_carapace clevis
compdef _sc_carapace col
compdef _sc_carapace colcrt
compdef _sc_carapace colormgr
compdef _sc_carapace colrm
compdef _sc_carapace conjure
compdef _sc_carapace coresched
compdef _sc_carapace cryptoflex-tool
compdef _sc_carapace ctrlaltdel
compdef _sc_carapace delpart
compdef _sc_carapace desktop-file-validate
compdef _sc_carapace devlink
compdef _sc_carapace dnie-tool
compdef _sc_carapace dot
compdef _sc_carapace dracut
compdef _sc_carapace dtrust-tool
compdef _sc_carapace dumpe2fs
compdef _sc_carapace e2freefrag
compdef _sc_carapace ebtables
compdef _sc_carapace edquota
compdef _sc_carapace egk-tool
compdef _sc_carapace eidenv
compdef _sc_carapace eject
compdef _sc_carapace enosys
compdef _sc_carapace ether-wake
compdef _sc_carapace exch
compdef _sc_carapace fadvise
compdef _sc_carapace fdformat
compdef _sc_carapace filefrag
compdef _sc_carapace fincore
compdef _sc_carapace findfs
compdef _sc_carapace flock
compdef _sc_carapace fpaste
compdef _sc_carapace fprintd-delete
compdef _sc_carapace fprintd-enroll
compdef _sc_carapace fprintd-list
compdef _sc_carapace fprintd-verify
compdef _sc_carapace fsck
compdef _sc_carapace fsck.cramfs
compdef _sc_carapace fsck.minix
compdef _sc_carapace fsfreeze
compdef _sc_carapace fstrim
compdef _sc_carapace fwupdtool
compdef _sc_carapace gapplication
compdef _sc_carapace gdbus
compdef _sc_carapace gendiff
compdef _sc_carapace ges-launch-1.0
compdef _sc_carapace getsebool
compdef _sc_carapace gids-tool
compdef _sc_carapace gluster
compdef _sc_carapace gnome-control-center
compdef _sc_carapace gnome-extensions
compdef _sc_carapace gnome-software
compdef _sc_carapace goid-tool
compdef _sc_carapace google-chrome-stable
compdef _sc_carapace gpgv2
compdef _sc_carapace gresource
compdef _sc_carapace grpck
compdef _sc_carapace gst-inspect-1.0
compdef _sc_carapace gst-launch-1.0
compdef _sc_carapace gtk4-builder-tool
compdef _sc_carapace hardlink
compdef _sc_carapace homectl
compdef _sc_carapace htpasswd
compdef _sc_carapace hwclock
compdef _sc_carapace iasecc-tool
compdef _sc_carapace ifstat
compdef _sc_carapace importctl
compdef _sc_carapace irqtop
compdef _sc_carapace iscsiadm
compdef _sc_carapace isosize
compdef _sc_carapace jps
compdef _sc_carapace jsonschema
compdef _sc_carapace kmod
compdef _sc_carapace lastlog2
compdef _sc_carapace localsearch
compdef _sc_carapace lsinitrd
compdef _sc_carapace lsmdev
compdef _sc_carapace luseradd
compdef _sc_carapace luserdel
compdef _sc_carapace lusermod
compdef _sc_carapace lvchange
compdef _sc_carapace lvcreate
compdef _sc_carapace lvdisplay
compdef _sc_carapace lvextend
compdef _sc_carapace lvm
compdef _sc_carapace lvmdiskscan
compdef _sc_carapace lvreduce
compdef _sc_carapace lvremove
compdef _sc_carapace lvrename
compdef _sc_carapace lvresize
compdef _sc_carapace lvs
compdef _sc_carapace lvscan
compdef _sc_carapace mbimcli
compdef _sc_carapace mdevctl
compdef _sc_carapace mesg
compdef _sc_carapace mii-diag
compdef _sc_carapace mkfs.cramfs
compdef _sc_carapace mkfs.minix
compdef _sc_carapace mmcli
compdef _sc_carapace mokutil
compdef _sc_carapace mountpoint
compdef _sc_carapace namei
compdef _sc_carapace ndctl
compdef _sc_carapace netkey-tool
compdef _sc_carapace newusers
compdef _sc_carapace npa-tool
compdef _sc_carapace nsupdate
compdef _sc_carapace openconnect
compdef _sc_carapace openpgp-tool
compdef _sc_carapace opensc-asn1
compdef _sc_carapace opensc-explorer
compdef _sc_carapace opensc-tool
compdef _sc_carapace ownership
compdef _sc_carapace partx
compdef _sc_carapace pipesz
compdef _sc_carapace piv-tool
compdef _sc_carapace pivot_root
compdef _sc_carapace pkcs11-tool
compdef _sc_carapace pkcs15-crypt
compdef _sc_carapace pkcs15-init
compdef _sc_carapace pkcs15-tool
compdef _sc_carapace pkgcli
compdef _sc_carapace pkgconf
compdef _sc_carapace pngfix
compdef _sc_carapace portablectl
compdef _sc_carapace prlimit
compdef _sc_carapace pvchange
compdef _sc_carapace pvcreate
compdef _sc_carapace pvdisplay
compdef _sc_carapace pvmove
compdef _sc_carapace pvremove
compdef _sc_carapace pvs
compdef _sc_carapace pvscan
compdef _sc_carapace pwck
compdef _sc_carapace qemu-kvm
compdef _sc_carapace qmicli
compdef _sc_carapace quota
compdef _sc_carapace quotacheck
compdef _sc_carapace quotaoff
compdef _sc_carapace quotaon
compdef _sc_carapace readprofile
compdef _sc_carapace repquota
compdef _sc_carapace resizepart
compdef _sc_carapace resolvconf
compdef _sc_carapace rpcdebug
compdef _sc_carapace rpmdev-bumpspec
compdef _sc_carapace rpmdev-checksig
compdef _sc_carapace rpmdev-cksum
compdef _sc_carapace rpmdev-diff
compdef _sc_carapace rpmdev-extract
compdef _sc_carapace rpmdev-md5
compdef _sc_carapace rpmdev-newspec
compdef _sc_carapace rpmdev-rmdevelrpms
compdef _sc_carapace rpmdev-setuptree
compdef _sc_carapace rpmdev-sha1
compdef _sc_carapace rpmdev-sha224
compdef _sc_carapace rpmdev-sha256
compdef _sc_carapace rpmdev-sha384
compdef _sc_carapace rpmdev-sha512
compdef _sc_carapace rpmdev-sum
compdef _sc_carapace rpmdev-vercmp
compdef _sc_carapace rpminfo
compdef _sc_carapace rpmls
compdef _sc_carapace rtcwake
compdef _sc_carapace runuser
compdef _sc_carapace sc-hsm-tool
compdef _sc_carapace secret-tool
compdef _sc_carapace semanage
compdef _sc_carapace setarch
compdef _sc_carapace setpgid
compdef _sc_carapace setquota
compdef _sc_carapace setsebool
compdef _sc_carapace setterm
compdef _sc_carapace sfdisk
compdef _sc_carapace smbcacls
compdef _sc_carapace smbcquotas
compdef _sc_carapace smbget
compdef _sc_carapace smbinfo
compdef _sc_carapace smbtar
compdef _sc_carapace smbtree
compdef _sc_carapace source-highlight
compdef _sc_carapace stream
compdef _sc_carapace systemd-confext
compdef _sc_carapace systemd-creds
compdef _sc_carapace systemd-cryptenroll
compdef _sc_carapace systemd-dissect
compdef _sc_carapace systemd-sysext
compdef _sc_carapace systemd-vmspawn
compdef _sc_carapace systemd-vpick
compdef _sc_carapace taskset
compdef _sc_carapace tc
compdef _sc_carapace tinysparql
compdef _sc_carapace tipc
compdef _sc_carapace tpm2
compdef _sc_carapace tpm2_activatecredential
compdef _sc_carapace tpm2_certify
compdef _sc_carapace tpm2_certifyX509certutil
compdef _sc_carapace tpm2_certifycreation
compdef _sc_carapace tpm2_changeauth
compdef _sc_carapace tpm2_changeeps
compdef _sc_carapace tpm2_changepps
compdef _sc_carapace tpm2_checkquote
compdef _sc_carapace tpm2_clear
compdef _sc_carapace tpm2_clearcontrol
compdef _sc_carapace tpm2_clockrateadjust
compdef _sc_carapace tpm2_commit
compdef _sc_carapace tpm2_create
compdef _sc_carapace tpm2_createak
compdef _sc_carapace tpm2_createek
compdef _sc_carapace tpm2_createpolicy
compdef _sc_carapace tpm2_createprimary
compdef _sc_carapace tpm2_dictionarylockout
compdef _sc_carapace tpm2_duplicate
compdef _sc_carapace tpm2_ecdhkeygen
compdef _sc_carapace tpm2_ecdhzgen
compdef _sc_carapace tpm2_ecephemeral
compdef _sc_carapace tpm2_encryptdecrypt
compdef _sc_carapace tpm2_eventlog
compdef _sc_carapace tpm2_evictcontrol
compdef _sc_carapace tpm2_flushcontext
compdef _sc_carapace tpm2_getcap
compdef _sc_carapace tpm2_getcommandauditdigest
compdef _sc_carapace tpm2_geteccparameters
compdef _sc_carapace tpm2_getekcertificate
compdef _sc_carapace tpm2_getrandom
compdef _sc_carapace tpm2_getsessionauditdigest
compdef _sc_carapace tpm2_gettestresult
compdef _sc_carapace tpm2_gettime
compdef _sc_carapace tpm2_hash
compdef _sc_carapace tpm2_hierarchycontrol
compdef _sc_carapace tpm2_hmac
compdef _sc_carapace tpm2_import
compdef _sc_carapace tpm2_incrementalselftest
compdef _sc_carapace tpm2_load
compdef _sc_carapace tpm2_loadexternal
compdef _sc_carapace tpm2_makecredential
compdef _sc_carapace tpm2_nvcertify
compdef _sc_carapace tpm2_nvdefine
compdef _sc_carapace tpm2_nvextend
compdef _sc_carapace tpm2_nvincrement
compdef _sc_carapace tpm2_nvread
compdef _sc_carapace tpm2_nvreadlock
compdef _sc_carapace tpm2_nvreadpublic
compdef _sc_carapace tpm2_nvsetbits
compdef _sc_carapace tpm2_nvundefine
compdef _sc_carapace tpm2_nvwrite
compdef _sc_carapace tpm2_nvwritelock
compdef _sc_carapace tpm2_pcrallocate
compdef _sc_carapace tpm2_pcrevent
compdef _sc_carapace tpm2_pcrextend
compdef _sc_carapace tpm2_pcrread
compdef _sc_carapace tpm2_pcrreset
compdef _sc_carapace tpm2_policyauthorize
compdef _sc_carapace tpm2_policyauthorizenv
compdef _sc_carapace tpm2_policyauthvalue
compdef _sc_carapace tpm2_policycommandcode
compdef _sc_carapace tpm2_policycountertimer
compdef _sc_carapace tpm2_policycphash
compdef _sc_carapace tpm2_policyduplicationselect
compdef _sc_carapace tpm2_policylocality
compdef _sc_carapace tpm2_policynamehash
compdef _sc_carapace tpm2_policynv
compdef _sc_carapace tpm2_policynvwritten
compdef _sc_carapace tpm2_policyor
compdef _sc_carapace tpm2_policypassword
compdef _sc_carapace tpm2_policypcr
compdef _sc_carapace tpm2_policyrestart
compdef _sc_carapace tpm2_policysecret
compdef _sc_carapace tpm2_policysigned
compdef _sc_carapace tpm2_policytemplate
compdef _sc_carapace tpm2_policyticket
compdef _sc_carapace tpm2_print
compdef _sc_carapace tpm2_quote
compdef _sc_carapace tpm2_rc_decode
compdef _sc_carapace tpm2_readclock
compdef _sc_carapace tpm2_readpublic
compdef _sc_carapace tpm2_rsadecrypt
compdef _sc_carapace tpm2_rsaencrypt
compdef _sc_carapace tpm2_selftest
compdef _sc_carapace tpm2_send
compdef _sc_carapace tpm2_setclock
compdef _sc_carapace tpm2_setcommandauditstatus
compdef _sc_carapace tpm2_setprimarypolicy
compdef _sc_carapace tpm2_shutdown
compdef _sc_carapace tpm2_sign
compdef _sc_carapace tpm2_startauthsession
compdef _sc_carapace tpm2_startup
compdef _sc_carapace tpm2_stirrandom
compdef _sc_carapace tpm2_testparms
compdef _sc_carapace tpm2_unseal
compdef _sc_carapace tpm2_verifysignature
compdef _sc_carapace tpm2_zgen2phase
compdef _sc_carapace traceroute6
compdef _sc_carapace tsig-keygen
compdef _sc_carapace tss2
compdef _sc_carapace tss2_authorizepolicy
compdef _sc_carapace tss2_changeauth
compdef _sc_carapace tss2_createkey
compdef _sc_carapace tss2_createnv
compdef _sc_carapace tss2_createseal
compdef _sc_carapace tss2_decrypt
compdef _sc_carapace tss2_delete
compdef _sc_carapace tss2_encrypt
compdef _sc_carapace tss2_exportkey
compdef _sc_carapace tss2_exportpolicy
compdef _sc_carapace tss2_getappdata
compdef _sc_carapace tss2_getcertificate
compdef _sc_carapace tss2_getdescription
compdef _sc_carapace tss2_getinfo
compdef _sc_carapace tss2_getplatformcertificates
compdef _sc_carapace tss2_getrandom
compdef _sc_carapace tss2_gettpm2object
compdef _sc_carapace tss2_gettpmblobs
compdef _sc_carapace tss2_import
compdef _sc_carapace tss2_list
compdef _sc_carapace tss2_nvextend
compdef _sc_carapace tss2_nvincrement
compdef _sc_carapace tss2_nvread
compdef _sc_carapace tss2_nvsetbits
compdef _sc_carapace tss2_nvwrite
compdef _sc_carapace tss2_pcrextend
compdef _sc_carapace tss2_pcrread
compdef _sc_carapace tss2_provision
compdef _sc_carapace tss2_quote
compdef _sc_carapace tss2_setappdata
compdef _sc_carapace tss2_setcertificate
compdef _sc_carapace tss2_setdescription
compdef _sc_carapace tss2_sign
compdef _sc_carapace tss2_unseal
compdef _sc_carapace tss2_verifyquote
compdef _sc_carapace tss2_verifysignature
compdef _sc_carapace tss2_writeauthorizenv
compdef _sc_carapace tuned-adm
compdef _sc_carapace uclampset
compdef _sc_carapace ul
compdef _sc_carapace utmpdump
compdef _sc_carapace vgcfgbackup
compdef _sc_carapace vgcfgrestore
compdef _sc_carapace vgchange
compdef _sc_carapace vgck
compdef _sc_carapace vgconvert
compdef _sc_carapace vgcreate
compdef _sc_carapace vgdisplay
compdef _sc_carapace vgexport
compdef _sc_carapace vgextend
compdef _sc_carapace vgimport
compdef _sc_carapace vgmerge
compdef _sc_carapace vgmknodes
compdef _sc_carapace vgreduce
compdef _sc_carapace vgremove
compdef _sc_carapace vgrename
compdef _sc_carapace vgs
compdef _sc_carapace vgscan
compdef _sc_carapace vgsplit
compdef _sc_carapace vigr
compdef _sc_carapace virt-clone
compdef _sc_carapace virt-install
compdef _sc_carapace virt-xml
compdef _sc_carapace vpddecode
compdef _sc_carapace waitpid
compdef _sc_carapace wall
compdef _sc_carapace westcos-tool
compdef _sc_carapace x264
compdef _sc_carapace xdg-settings
compdef _sc_carapace xmlwf
compdef _sc_carapace xzdec
compdef _sc_carapace epiphany
compdef _sc_carapace ld
compdef _sc_carapace m4
compdef _sc_carapace mpg123
compdef _sc_carapace objcopy
compdef _sc_carapace oocalc
compdef _sc_carapace ooimpress
compdef _sc_carapace oowriter
compdef _sc_carapace realpath
compdef _sc_carapace rpm2cpio
compdef _sc_carapace znew

# Current OMZ has a more specific menu select style.
zstyle ':completion:*:*:*:*:*' menu no
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'

compdef _sc_carapace npm adb
compdef _sc_native_ffplay ffplay
compdef _sc_native_ffprobe ffprobe
compdef _sc_native_magick magick
compdef _sc_native_compare compare
compdef _sc_carapace carapace
# Refreshing in this shell invalidates its cached resolution as well.
refresh-completions() {
  command "$HOME/.local/bin/refresh-completions" "$@" || return
  _SC_NATIVE_PATH=()
}
_sc_refresh_completions() {
  _arguments '--help[show help]' '--force[regenerate completions]' \
    '--resolve[resolve one command]:command:(codex gh uv uvx k9s lazygit k6 argocd cosign oras rustup cf bw trash trash-put trash-list trash-empty trash-restore ai-cli yazi ya cargo ffplay ffprobe magick compare)' \
    '*:command:(codex gh uv uvx k9s lazygit k6 argocd cosign oras rustup cf bw trash trash-put trash-list trash-empty trash-restore ai-cli yazi ya cargo ffplay ffprobe magick compare)'
}
compdef _sc_refresh_completions refresh-completions

source "$HOME/.config/shell-completion/repairs.zsh"
