# 설정과 기기 데이터

공유 기본값은 home/.chezmoidata.toml, 업스트림 revision·선별된 completion 목록은 home/.chezmoidata.json, 초기 기기 선택은 home/.chezmoi.toml.tmpl에 둔다. 실제 기기 선택은 로컬 chezmoi config의 [data]가 소유한다. 기기 config 자체는 저장소에 복사하지 않는다.

config sourceDir는 Git checkout 루트인 .chezmoi.workingTree에서 유도한다. .chezmoiroot 적용 후 템플릿 .chezmoi.sourceDir는 home 하위 디렉터리다. config를 --source 없이 다시 읽는 검사로 둘을 구분한다.

## 기본값과 플랫폼 선택

배포 enabled/externals는 모두 false다. Conda·Bitwarden·개인 Fedora 도구·웹 편집기 구성도 기본 false다. OS가 Fedora이거나 도구가 설치되어 있다는 이유로 개인 기능을 자동 선택하지 않는다. 플랫폼만 초기화한 것은 Fedora 설정을 적용한 것이 아니다.

기존 Fedora 선택의 비밀정보 없는 예는 [기기 데이터 예시](fedora-machine.example.toml)에 있다. 실제 적용 전 단계에서 선택한다. prefix/socket은 정상적인 홈 하위 기본 경로를 유도하고 다른 위치를 쓰면 기기 데이터로 지정한다. 초기화 템플릿은 기존 선택을 반복 초기화에서 보존한다.

`.chezmoiignore`는 enabled=false일 때 모든 대상을 제외한다. enabled=true라도 Fedora/Ubuntu 외에는 제외한다. personal_fedora=true인 Ubuntu는 오류로 거부한다. 두 플랫폼에서는 README·빈 Ghostty/PowerShell 예약 경로·선택하지 않은 기능을 제외한다. `.chezmoiexternal`은 enabled와 externals를 모두 명시적으로 켤 때만 선언을 생성한다. 개인 Fedora는 enabled=true, externals=false로 적용했다. 기존 OMZ/tmux 플러그인과 로컬 패치를 유지하며 archive를 덮어쓰지 않았다.

## 실제 source

| 소스 | 대상/역할 |
|---|---|
| dot_zshrc.tmpl, modify_dot_bashrc | Zsh·Fedora 보조 Bash·Ubuntu Bash 보존 |
| modify_dot_gitconfig + dot_config/git/config.tmpl | identity 보존 + 공통 Git 동작 |
| dot_config/private_gh/modify_private_config.yml | gh의 검토한 키만 갱신 |
| dot_config/mise/config*.toml + miserc.toml.tmpl | 공통·AI·Fedora 개인 도구·Ubuntu 편집기 런타임과 기기 선택 |
| dot_tmux.conf.local + symlink_dot_tmux.conf.tmpl | 기존 Oh My Tmux 사용자 설정과 링크 |
| dot_config/nvim | LazyVim 사용자 설정·잠금·선택적 웹 기능 |
| dot_config/shell-completion, dot_config/carapace, dot_local | 기존 Fedora completion 구현·정책·어댑터 |
| private_dot_claude/modify_private_settings.json | Claude theme/tui 선호, 기존 훅 보존 |
| private_dot_codex/modify_private_config.toml | Codex 현재 model/reasoning/service 선호, 나머지 보존 |
| dot_config/opencode/modify_opencode.json | 기존 autoupdate=false |

Git identity와 signing key는 실제 .gitconfig에 남긴다. Git helper만 안정적인 mise shims/gh로 연결하고 빈 reset 항목은 보존한다. 개인 AI 지침과 PowerShell 실제 프로필은 아직 source를 작성하지 않았다.

## 적용 전 검토에서 수정한 보존 규칙

- gh는 관리 값이 이미 같으면 입력 원문을 바이트 그대로 반환한다. 변경이 필요하면 일반 block YAML의 `git_protocol`과 `aliases.co` 줄만 갱신한다. 빈 scalar, 주석, 다른 alias/미관리 값은 그대로 둔다. 전체 파싱 결과를 기대 문서와 비교하며, 안전하게 수정할 수 없는 flow/quoted-key 형태는 덮어쓰지 않고 오류로 중단한다. 이미 값이 같은 flow YAML은 그대로 사용할 수 있다.
- AI 세 파일도 선호 값이 같으면 원문을 그대로 반환한다. 값 변경이 필요한 경우에만 파싱한 문서를 재출력하므로 그때는 주석과 포맷이 바뀔 수 있다.
- `dot_local/private_share`는 `.local/share`의 기존 700을 유지한다. completion 파일의 최종 경로와 내용은 바뀌지 않는다.
- `dot_config/private_gh/modify_private_config.yml`은 디렉터리 700 / 파일 600을 선언한다. 개인 Fedora gh 디렉터리는 적용 시 751에서 700으로 제한했다. chezmoi의 source 속성으로 개별 디렉터리 751을 표현할 수 없으므로, 별도 chmod 스크립트를 추가하지 않고 사용자 전용 권한을 선택했다. 그룹/다른 사용자 접근이 필요한 공유 gh 설정에는 이 선택을 그대로 적용하지 않는다.
- `.claude`·`.codex` 디렉터리도 사용자 전용 700이며 Claude settings 파일은 600이다. 이 권한 변경도 개인 Fedora에 적용했고 원래 권한은 비공개 복구본에 기록했다.

`dot_local/bin/symlink_carapace.tmpl`는 기존 ~/.local/bin/carapace 진입점을 유지하면서 mise shim으로 연결한다. 수동 실행 파일은 Fedora 이전 시 비공개 복구본에 보존한다. Zsh의 mise activation을 거치지 않은 Bash/기존 스크립트도 같은 고정 버전으로 연결되며 install inventory는 mise 한 곳에만 둔다.

## Ubuntu 차이

Ubuntu의 modify_dot_bashrc는 기존 .bashrc 끝에 공통 모듈 로드 한 줄만 추가하며 반복 적용 시 중복하지 않는다. .profile과 .bash_logout은 관리하지 않는다. Fedora의 기존 Bash 출력은 .chezmoitemplates/shell/fedora.bashrc.tmpl로 옮겼으며 렌더링 결과는 유지한다.

Ubuntu의 .config/shell/bashrc.bash는 mise·fzf 단축키·zoxide와 선택적 carapace 공급자를 초기화한다. fzf --bash 초기화 전 native completion 등록을 저장하고 복원하여 Ubuntu의 Tab 공급자를 유지한다. Zsh도 OMZ/기본 공급자가 없을 때만 선택한 CLI의 carapace 공급자를 연결한다. Fedora RPM completion·native adapter·spec 복사본은 Ubuntu에 배포하지 않는다. 공유 carapace 본문은 template 한 곳에서 소유한다.

Ubuntu 기기 초기화 config에는 chezmoi 전용 umask=0o077을 지정한다. 기존 .config/.local/.local/share의 700을 유지하고 관리 일반 파일은 600으로 만든다. 기존 .bashrc의 644→600도 의도한 변화다. OS/셸 umask는 변경하지 않는다. Fedora config에는 이 전역 정책을 추가하지 않는다.
