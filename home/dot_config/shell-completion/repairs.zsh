# Specific providers take precedence over generic file/no-argument rules.
compdef _sc_carapace whoami logname sync pdffonts pdfimages pdfinfo pdftoppm pdftops pdftotext
compdef _python_argcomplete virt-install virt-clone virt-xml
compdef _sc_carapace mdevctl
_sc_pwd() {
  if [[ $(whence -w -- "$words[1]") == *': builtin' ]]; then
    _arguments '-L[use the logical directory]' '-P[use the physical directory]'
  else
    _sc_carapace "$@"
  fi
}
compdef _sc_pwd pwd
_sc_domainname() {
  _arguments \
    '(-h --help)'{-h,--help}'[show help]' \
    '(-V --version)'{-V,--version}'[show version]' \
    '(-F --file)'{-F+,--file=}'[read NIS domain name from file]:file:_files' \
    '1:NIS domain name:'
}
compdef _sc_domainname domainname
_sc_service_names() {
  local expl
  local -a units scripts
  units=( /etc/systemd/system/*.service(N:t:r) /run/systemd/system/*.service(N:t:r) /usr/lib/systemd/system/*.service(N:t:r) )
  scripts=( /etc/init.d/*(N-*:t) )
  scripts=( ${scripts:#functions} )
  local -aU names=( $units $scripts )
  _wanted services expl 'service' compadd -a names
}
_sc_service() {
  _arguments \
    '(-h --help)'{-h,--help}'[show help]' \
    '(-V --version)'{-V,--version}'[show version]' \
    '--ignore-dependencies[ignore service dependencies]' \
    '--skip-redirect[use the init script]' \
    '--status-all[show all init script status]' \
    '1:service:_sc_service_names' \
    '*:action:(start stop restart try-restart reload force-reload status --full-restart)'
}
compdef _sc_service service

# Keep native argument logic while bounding its external lookups.
for _sc_tag in selinux-users selinux-roles selinux-types info-nodes menu-items index-entries atoms; do
  zstyle ":completion:*:${_sc_tag}" command '-/usr/bin/timeout --kill-after=0.2s 1s'
done
zstyle ':completion:*:look:*:words' command '/usr/bin/timeout --kill-after=0.2s 1s "${words[1]}" "$PREFIX" | /usr/bin/head -n 200'
unset _sc_tag
zstyle ':completion:*:options' prefix-needed false
autoload -Uz _look
_sc_look() {
  if [[ $CURRENT == 2 && -z $PREFIX$SUFFIX ]]; then
    _arguments \
      '(-a --alternative)'{-a,--alternative}'[use alternative dictionary]' \
      '(-d --alphanum)'{-d,--alphanum}'[dictionary order]' \
      '(-f --ignore-case)'{-f,--ignore-case}'[ignore case]' \
      '(-t --terminate)'{-t+,--terminate=}'[termination character]:character:' \
      '(-h --help)'{-h,--help}'[show help]' \
      '(-V --version)'{-V,--version}'[show version]' \
      '1:word prefix:' '2:dictionary file:_files'
  else
    _look "$@"
  fi
}
compdef _sc_look look
_sc_clear() {
  _arguments '-T[terminal type]:terminal:_terminals' '-V[show version]' '-x[preserve scrollback]'
}
compdef _sc_clear clear
for _sc_name in chcon look domainname service clear; do
  zstyle ":completion:*:${_sc_name}:*" tag-order '(options *)'
done
unset _sc_name
zstyle ':completion:*:animate:*' tag-order '(options *)'
zstyle ':completion:*:ansible-playbook:*' tag-order '(options *)'
zstyle ':completion:*:ansible-pull:*' tag-order '(options *)'
zstyle ':completion:*:antiword:*' tag-order '(options *)'
zstyle ':completion:*:aplay:*' tag-order '(options *)'
zstyle ':completion:*:arecord:*' tag-order '(options *)'
zstyle ':completion:*:at:*' tag-order '(options *)'
zstyle ':completion:*:atrm:*' tag-order '(options *)'
zstyle ':completion:*:attr:*' tag-order '(options *)'
zstyle ':completion:*:avahi-browse:*' tag-order '(options *)'
zstyle ':completion:*:avahi-browse-domains:*' tag-order '(options *)'
zstyle ':completion:*:b2sum:*' tag-order '(options *)'
zstyle ':completion:*:base32:*' tag-order '(options *)'
zstyle ':completion:*:base64:*' tag-order '(options *)'
zstyle ':completion:*:basename:*' tag-order '(options *)'
zstyle ':completion:*:basenc:*' tag-order '(options *)'
zstyle ':completion:*:bash:*' tag-order '(options *)'
zstyle ':completion:*:bat:*' tag-order '(options *)'
zstyle ':completion:*:batch:*' tag-order '(options *)'
zstyle ':completion:*:bison:*' tag-order '(options *)'
zstyle ':completion:*:bunzip2:*' tag-order '(options *)'
zstyle ':completion:*:bwrap:*' tag-order '(options *)'
zstyle ':completion:*:bzcat:*' tag-order '(options *)'
zstyle ':completion:*:bzegrep:*' tag-order '(options *)'
zstyle ':completion:*:bzfgrep:*' tag-order '(options *)'
zstyle ':completion:*:bzgrep:*' tag-order '(options *)'
zstyle ':completion:*:bzip2:*' tag-order '(options *)'
zstyle ':completion:*:c++:*' tag-order '(options *)'
zstyle ':completion:*:cal:*' tag-order '(options *)'
zstyle ':completion:*:cat:*' tag-order '(options *)'
zstyle ':completion:*:cc:*' tag-order '(options *)'
zstyle ':completion:*:chroot:*' tag-order '(options *)'
zstyle ':completion:*:chrt:*' tag-order '(options *)'
zstyle ':completion:*:cksum:*' tag-order '(options *)'
zstyle ':completion:*:cmake:*' tag-order '(options *)'
zstyle ':completion:*:cmp:*' tag-order '(options *)'
zstyle ':completion:*:code:*' tag-order '(options *)'
zstyle ':completion:*:column:*' tag-order '(options *)'
zstyle ':completion:*:comm:*' tag-order '(options *)'
zstyle ':completion:*:compare:*' tag-order '(options *)'
zstyle ':completion:*:composite:*' tag-order '(options *)'
zstyle ':completion:*:convert:*' tag-order '(options *)'
zstyle ':completion:*:cp:*' tag-order '(options *)'
zstyle ':completion:*:crontab:*' tag-order '(options *)'
zstyle ':completion:*:csplit:*' tag-order '(options *)'
zstyle ':completion:*:ctags:*' tag-order '(options *)'
zstyle ':completion:*:cut:*' tag-order '(options *)'
zstyle ':completion:*:date:*' tag-order '(options *)'
zstyle ':completion:*:dbus-send:*' tag-order '(options *)'
zstyle ':completion:*:diff:*' tag-order '(options *)'
zstyle ':completion:*:diff3:*' tag-order '(options *)'
zstyle ':completion:*:display:*' tag-order '(options *)'
zstyle ':completion:*:distrobox-create:*' tag-order '(options *)'
zstyle ':completion:*:distrobox-ephemeral:*' tag-order '(options *)'
zstyle ':completion:*:dos2unix:*' tag-order '(options *)'
zstyle ':completion:*:du:*' tag-order '(options *)'
zstyle ':completion:*:ed:*' tag-order '(options *)'
zstyle ':completion:*:epsffit:*' tag-order '(options *)'
zstyle ':completion:*:eu-nm:*' tag-order '(options *)'
zstyle ':completion:*:eu-objdump:*' tag-order '(options *)'
zstyle ':completion:*:eu-readelf:*' tag-order '(options *)'
zstyle ':completion:*:eu-strings:*' tag-order '(options *)'
zstyle ':completion:*:ex:*' tag-order '(options *)'
zstyle ':completion:*:expand:*' tag-order '(options *)'
zstyle ':completion:*:extractres:*' tag-order '(options *)'
zstyle ':completion:*:fallocate:*' tag-order '(options *)'
zstyle ':completion:*:fastboot:*' tag-order '(options *)'
zstyle ':completion:*:fd:*' tag-order '(options *)'
zstyle ':completion:*:ffmpeg:*' tag-order '(options *)'
zstyle ':completion:*:ffplay:*' tag-order '(options *)'
zstyle ':completion:*:ffprobe:*' tag-order '(options *)'
zstyle ':completion:*:find:*' tag-order '(options *)'
zstyle ':completion:*:firefox:*' tag-order '(options *)'
zstyle ':completion:*:flex:*' tag-order '(options *)'
zstyle ':completion:*:flex++:*' tag-order '(options *)'
zstyle ':completion:*:fmt:*' tag-order '(options *)'
zstyle ':completion:*:fold:*' tag-order '(options *)'
zstyle ':completion:*:fuser:*' tag-order '(options *)'
zstyle ':completion:*:fusermount:*' tag-order '(options *)'
zstyle ':completion:*:g++:*' tag-order '(options *)'
zstyle ':completion:*:gcc:*' tag-order '(options *)'
zstyle ':completion:*:gcc-ar:*' tag-order '(options *)'
zstyle ':completion:*:gcc-nm:*' tag-order '(options *)'
zstyle ':completion:*:gcc-ranlib:*' tag-order '(options *)'
zstyle ':completion:*:gdb:*' tag-order '(options *)'
zstyle ':completion:*:genisoimage:*' tag-order '(options *)'
zstyle ':completion:*:getfacl:*' tag-order '(options *)'
zstyle ':completion:*:getfattr:*' tag-order '(options *)'
zstyle ':completion:*:ghostscript:*' tag-order '(options *)'
zstyle ':completion:*:git-receive-pack:*' tag-order '(options *)'
zstyle ':completion:*:git-shell:*' tag-order '(options *)'
zstyle ':completion:*:git-upload-pack:*' tag-order '(options *)'
zstyle ':completion:*:gmake:*' tag-order '(options *)'
zstyle ':completion:*:gpg:*' tag-order '(options *)'
zstyle ':completion:*:gpg2:*' tag-order '(options *)'
zstyle ':completion:*:gpgv:*' tag-order '(options *)'
zstyle ':completion:*:gprof:*' tag-order '(options *)'
zstyle ':completion:*:groff:*' tag-order '(options *)'
zstyle ':completion:*:growisofs:*' tag-order '(options *)'
zstyle ':completion:*:gs:*' tag-order '(options *)'
zstyle ':completion:*:gunzip:*' tag-order '(options *)'
zstyle ':completion:*:gzip:*' tag-order '(options *)'
zstyle ':completion:*:head:*' tag-order '(options *)'
zstyle ':completion:*:hexdump:*' tag-order '(options *)'
zstyle ':completion:*:hostname:*' tag-order '(options *)'
zstyle ':completion:*:iconv:*' tag-order '(options *)'
zstyle ':completion:*:iconvconfig:*' tag-order '(options *)'
zstyle ':completion:*:identify:*' tag-order '(options *)'
zstyle ':completion:*:import:*' tag-order '(options *)'
zstyle ':completion:*:insmod:*' tag-order '(options *)'
zstyle ':completion:*:install:*' tag-order '(options *)'
zstyle ':completion:*:jarsigner:*' tag-order '(options *)'
zstyle ':completion:*:java:*' tag-order '(options *)'
zstyle ':completion:*:javac:*' tag-order '(options *)'
zstyle ':completion:*:javadoc:*' tag-order '(options *)'
zstyle ':completion:*:javap:*' tag-order '(options *)'
zstyle ':completion:*:jdb:*' tag-order '(options *)'
zstyle ':completion:*:jobs:*' tag-order '(options *)'
zstyle ':completion:*:join:*' tag-order '(options *)'
zstyle ':completion:*:jq:*' tag-order '(options *)'
zstyle ':completion:*:kpartx:*' tag-order '(options *)'
zstyle ':completion:*:ldattach:*' tag-order '(options *)'
zstyle ':completion:*:ldconfig:*' tag-order '(options *)'
zstyle ':completion:*:ldd:*' tag-order '(options *)'
zstyle ':completion:*:less:*' tag-order '(options *)'
zstyle ':completion:*:ln:*' tag-order '(options *)'
zstyle ':completion:*:loadkeys:*' tag-order '(options *)'
zstyle ':completion:*:localedef:*' tag-order '(options *)'
zstyle ':completion:*:locate:*' tag-order '(options *)'
zstyle ':completion:*:losetup:*' tag-order '(options *)'
zstyle ':completion:*:lp:*' tag-order '(options *)'
zstyle ':completion:*:lpq:*' tag-order '(options *)'
zstyle ':completion:*:lpr:*' tag-order '(options *)'
zstyle ':completion:*:lprm:*' tag-order '(options *)'
zstyle ':completion:*:ls:*' tag-order '(options *)'
zstyle ':completion:*:lsattr:*' tag-order '(options *)'
zstyle ':completion:*:lsof:*' tag-order '(options *)'
zstyle ':completion:*:lzop:*' tag-order '(options *)'
zstyle ':completion:*:mac2unix:*' tag-order '(options *)'
zstyle ':completion:*:magick:*' tag-order '(options *)'
zstyle ':completion:*:make:*' tag-order '(options *)'
zstyle ':completion:*:md5sum:*' tag-order '(options *)'
zstyle ':completion:*:mkdir:*' tag-order '(options *)'
zstyle ':completion:*:mkfifo:*' tag-order '(options *)'
zstyle ':completion:*:mkisofs:*' tag-order '(options *)'
zstyle ':completion:*:mknod:*' tag-order '(options *)'
zstyle ':completion:*:mogrify:*' tag-order '(options *)'
zstyle ':completion:*:montage:*' tag-order '(options *)'
zstyle ':completion:*:mv:*' tag-order '(options *)'
zstyle ':completion:*:nano:*' tag-order '(options *)'
zstyle ':completion:*:ninja:*' tag-order '(options *)'
zstyle ':completion:*:nl:*' tag-order '(options *)'
zstyle ':completion:*:nm:*' tag-order '(options *)'
zstyle ':completion:*:nvim:*' tag-order '(options *)'
zstyle ':completion:*:objdump:*' tag-order '(options *)'
zstyle ':completion:*:od:*' tag-order '(options *)'
zstyle ':completion:*:oggdec:*' tag-order '(options *)'
zstyle ':completion:*:oggenc:*' tag-order '(options *)'
zstyle ':completion:*:ogginfo:*' tag-order '(options *)'
zstyle ':completion:*:pacat:*' tag-order '(options *)'
zstyle ':completion:*:paplay:*' tag-order '(options *)'
zstyle ':completion:*:parec:*' tag-order '(options *)'
zstyle ':completion:*:parecord:*' tag-order '(options *)'
zstyle ':completion:*:paste:*' tag-order '(options *)'
zstyle ':completion:*:patch:*' tag-order '(options *)'
zstyle ':completion:*:perl:*' tag-order '(options *)'
zstyle ':completion:*:pg_restore:*' tag-order '(options *)'
zstyle ':completion:*:pr:*' tag-order '(options *)'
zstyle ':completion:*:prove:*' tag-order '(options *)'
zstyle ':completion:*:psbook:*' tag-order '(options *)'
zstyle ':completion:*:psnup:*' tag-order '(options *)'
zstyle ':completion:*:psresize:*' tag-order '(options *)'
zstyle ':completion:*:psselect:*' tag-order '(options *)'
zstyle ':completion:*:pstops:*' tag-order '(options *)'
zstyle ':completion:*:ptx:*' tag-order '(options *)'
zstyle ':completion:*:pygmentize:*' tag-order '(options *)'
zstyle ':completion:*:python:*' tag-order '(options *)'
zstyle ':completion:*:python3:*' tag-order '(options *)'
zstyle ':completion:*:python3.14:*' tag-order '(options *)'
zstyle ':completion:*:qemu-system-i386:*' tag-order '(options *)'
zstyle ':completion:*:qemu-system-x86_64:*' tag-order '(options *)'
zstyle ':completion:*:ranlib:*' tag-order '(options *)'
zstyle ':completion:*:readelf:*' tag-order '(options *)'
zstyle ':completion:*:readlink:*' tag-order '(options *)'
zstyle ':completion:*:rm:*' tag-order '(options *)'
zstyle ':completion:*:rmdir:*' tag-order '(options *)'
zstyle ':completion:*:rview:*' tag-order '(options *)'
zstyle ':completion:*:script:*' tag-order '(options *)'
zstyle ':completion:*:scriptreplay:*' tag-order '(options *)'
zstyle ':completion:*:scrub:*' tag-order '(options *)'
zstyle ':completion:*:serialver:*' tag-order '(options *)'
zstyle ':completion:*:setfacl:*' tag-order '(options *)'
zstyle ':completion:*:setfattr:*' tag-order '(options *)'
zstyle ':completion:*:sh:*' tag-order '(options *)'
zstyle ':completion:*:sha1sum:*' tag-order '(options *)'
zstyle ':completion:*:sha224sum:*' tag-order '(options *)'
zstyle ':completion:*:sha256sum:*' tag-order '(options *)'
zstyle ':completion:*:sha384sum:*' tag-order '(options *)'
zstyle ':completion:*:sha512sum:*' tag-order '(options *)'
zstyle ':completion:*:shasum:*' tag-order '(options *)'
zstyle ':completion:*:shellcheck:*' tag-order '(options *)'
zstyle ':completion:*:shred:*' tag-order '(options *)'
zstyle ':completion:*:shuf:*' tag-order '(options *)'
zstyle ':completion:*:shutdown:*' tag-order '(options *)'
zstyle ':completion:*:sort:*' tag-order '(options *)'
zstyle ':completion:*:soxi:*' tag-order '(options *)'
zstyle ':completion:*:split:*' tag-order '(options *)'
zstyle ':completion:*:ssh-add:*' tag-order '(options *)'
zstyle ':completion:*:stat:*' tag-order '(options *)'
zstyle ':completion:*:strings:*' tag-order '(options *)'
zstyle ':completion:*:strip:*' tag-order '(options *)'
zstyle ':completion:*:subl:*' tag-order '(options *)'
zstyle ':completion:*:sudoedit:*' tag-order '(options *)'
zstyle ':completion:*:sum:*' tag-order '(options *)'
zstyle ':completion:*:swaplabel:*' tag-order '(options *)'
zstyle ':completion:*:swapoff:*' tag-order '(options *)'
zstyle ':completion:*:swapon:*' tag-order '(options *)'
zstyle ':completion:*:systemd-inhibit:*' tag-order '(options *)'
zstyle ':completion:*:systemd-tmpfiles:*' tag-order '(options *)'
zstyle ':completion:*:tac:*' tag-order '(options *)'
zstyle ':completion:*:tail:*' tag-order '(options *)'
zstyle ':completion:*:tee:*' tag-order '(options *)'
zstyle ':completion:*:timeout:*' tag-order '(options *)'
zstyle ':completion:*:touch:*' tag-order '(options *)'
zstyle ':completion:*:tr:*' tag-order '(options *)'
zstyle ':completion:*:trash:*' tag-order '(options *)'
zstyle ':completion:*:trash-empty:*' tag-order '(options *)'
zstyle ':completion:*:trash-list:*' tag-order '(options *)'
zstyle ':completion:*:trash-put:*' tag-order '(options *)'
zstyle ':completion:*:trash-restore:*' tag-order '(options *)'
zstyle ':completion:*:tree:*' tag-order '(options *)'
zstyle ':completion:*:truncate:*' tag-order '(options *)'
zstyle ':completion:*:tune2fs:*' tag-order '(options *)'
zstyle ':completion:*:ulimit:*' tag-order '(options *)'
zstyle ':completion:*:unexpand:*' tag-order '(options *)'
zstyle ':completion:*:uniq:*' tag-order '(options *)'
zstyle ':completion:*:unix2dos:*' tag-order '(options *)'
zstyle ':completion:*:unix2mac:*' tag-order '(options *)'
zstyle ':completion:*:unxz:*' tag-order '(options *)'
zstyle ':completion:*:unzip:*' tag-order '(options *)'
zstyle ':completion:*:uvx:*' tag-order '(options *)'
zstyle ':completion:*:vi:*' tag-order '(options *)'
zstyle ':completion:*:view:*' tag-order '(options *)'
zstyle ':completion:*:virt-xml-validate:*' tag-order '(options *)'
zstyle ':completion:*:vorbiscomment:*' tag-order '(options *)'
zstyle ':completion:*:wc:*' tag-order '(options *)'
zstyle ':completion:*:who:*' tag-order '(options *)'
zstyle ':completion:*:xclip:*' tag-order '(options *)'
zstyle ':completion:*:xmodmap:*' tag-order '(options *)'
zstyle ':completion:*:xrdb:*' tag-order '(options *)'
zstyle ':completion:*:xsltproc:*' tag-order '(options *)'
zstyle ':completion:*:xz:*' tag-order '(options *)'
zstyle ':completion:*:xzcat:*' tag-order '(options *)'
zstyle ':completion:*:yazi:*' tag-order '(options *)'
zstyle ':completion:*:zcat:*' tag-order '(options *)'
zstyle ':completion:*:zip:*' tag-order '(options *)'
zstyle ':completion:*:zipinfo:*' tag-order '(options *)'
zstyle ':completion:*:zsh:*' tag-order '(options *)'

typeset -gA _SC_ROOT_OPTIONS=(
  acpid 1
  alsamixer 1
  ar 1
  autoconf 1
  autoheader 1
  automake 1
  autoreconf 1
  autoscan 1
  autoupdate 1
  baobab 1
  bc 1
  biosdecode 1
  bits 1
  brotli 1
  cargo-clippy 1
  cargo-fmt 1
  chronyc 1
  colcrt 1
  conjure 1
  dc 1
  desktop-file-validate 1
  dir 1
  dircolors 1
  dirname 1
  dnsmasq 1
  dockerd 1
  dot 1
  dracut 1
  ebtables 1
  eject 1
  envsubst 1
  exch 1
  expr 1
  factor 1
  fadvise 1
  fc-cache 1
  fc-cat 1
  fc-conflist 1
  file 1
  filefrag 1
  fpaste 1
  fzf 1
  ges-launch-1.0 1
  gnome-keyring-daemon 1
  gnome-maps 1
  google-chrome 1
  google-chrome-stable 1
  gpg-agent 1
  gpgv2 1
  groupmems 1
  grpck 1
  halt 1
  hardlink 1
  hostid 1
  htpasswd 1
  hugetop 1
  hunspell 1
  hwclock 1
  ifstat 1
  isosize 1
  jsonschema 1
  lastlog2 1
  ld 1
  link 1
  lsclocks 1
  lsfd 1
  lsirq 1
  lvchange 1
  lvcreate 1
  lvdisplay 1
  lvextend 1
  lvmdiskscan 1
  lvreduce 1
  lvremove 1
  lvrename 1
  lvresize 1
  lvs 1
  lvscan 1
  m4 1
  mitmproxy 1
  mokutil 1
  more 1
  namei 1
  newusers 1
  nproc 1
  nsupdate 1
  objcopy 1
  ownership 1
  pathchk 1
  pdfattach 1
  pdfdetach 1
  pdfseparate 1
  pdfsig 1
  pdftocairo 1
  pdftohtml 1
  pdfunite 1
  pkgconf 1
  pngfix 1
  poweroff 1
  pvchange 1
  pvdisplay 1
  pvmove 1
  pvremove 1
  pvs 1
  pvscan 1
  pwck 1
  pwd 1
  qemu-io 1
  qemu-kvm 1
  qemu-nbd 1
  qemu-pr-helper 1
  qemu-storage-daemon 1
  qemu-vmsr-helper 1
  qrencode 1
  realpath 1
  reboot 1
  rename 1
  resolvconf 1
  rpcdebug 1
  rpmdev-bumpspec 1
  rpmdev-diff 1
  rpmdev-extract 1
  rpmdev-newspec 1
  rpmdev-setuptree 1
  rpmdev-vercmp 1
  rustc 1
  rustdoc 1
  scriptlive 1
  showkey 1
  sleep 1
  smbcacls 1
  smbcquotas 1
  smbget 1
  smbtar 1
  smbtree 1
  stream 1
  sudoreplay 1
  sulogin 1
  systemd-cryptenroll 1
  tmate 1
  tshark 1
  tsig-keygen 1
  tsort 1
  ul 1
  unlink 1
  users 1
  utmpdump 1
  vdir 1
  vgcfgbackup 1
  vgcfgrestore 1
  vgchange 1
  vgck 1
  vgconvert 1
  vgcreate 1
  vgdisplay 1
  vgexport 1
  vgextend 1
  vgimport 1
  vgmerge 1
  vgmknodes 1
  vgreduce 1
  vgremove 1
  vgrename 1
  vgs 1
  vgscan 1
  vgsplit 1
  vlc 1
  vpddecode 1
  wireshark 1
  x264 1
  xmlwf 1
  xzdec 1
  yes 1
  whoami 1
  logname 1
  sync 1
  pdffonts 1
  pdfimages 1
  pdfinfo 1
  pdftoppm 1
  pdftops 1
  pdftotext 1
)
_sc_carapace() {
  _sc_carapace_base "$@"
  if [[ $CURRENT == 2 && -z $PREFIX$SUFFIX && -n ${_SC_ROOT_OPTIONS[$words[1]]-} ]]; then
    local _SC_OPTIONS_QUERY=1
    _sc_carapace_base "$@"
  fi
}
