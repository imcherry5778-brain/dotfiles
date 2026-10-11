# 설정과 기기 데이터

공유 기본값은 home/.chezmoidata.toml, 업스트림 revision·선별된 completion 목록은 home/.chezmoidata.json, 초기 기기 선택은 home/.chezmoi.toml.tmpl에 둔다. 실제 기기 선택은 로컬 chezmoi config의 [data]가 소유한다. 기기 config 자체는 저장소에 복사하지 않는다.

config sourceDir는 Git checkout 루트인 .chezmoi.workingTree에서 유도한다. .chezmoiroot 적용 후 템플릿 .chezmoi.sourceDir는 home 하위 디렉터리다. config를 --source 없이 다시 읽는 검사로 둘을 구분한다.

## 기본값과 Fedora 선택

배포 enabled/externals는 모두 false다. Conda·Bitwarden·개인 Fedora 도구·웹 편집기 구성도 기본 false다. OS가 Fedora이거나 도구가 설치되어 있다는 이유로 개인 기능을 자동 선택하지 않는다. 플랫폼만 초기화한 것은 Fedora 설정을 적용한 것이 아니다.

기존 Fedora 선택의 비밀정보 없는 예는 [기기 데이터 예시](fedora-machine.example.toml)에 있다. 실제 적용 전 단계에서 선택한다. prefix/socket은 정상적인 홈 하위 기본 경로를 유도하고 다른 위치를 쓰면 기기 데이터로 지정한다. 초기화 템플릿은 기존 선택을 반복 초기화에서 보존한다.

`.chezmoiignore`는 enabled=false일 때 모든 대상을 제외한다. enabled=true라도 Fedora 외에는 제외한다. Fedora에서는 README·빈 Ghostty/PowerShell 예약 경로·선택하지 않은 기능을 제외한다. `.chezmoiexternal`은 enabled와 externals를 모두 명시적으로 켤 때만 선언을 생성한다. 현재 실제 홈에 이 값을 설정하지 않았다.

## 실제 source

| 소스 | 대상/역할 |
|---|---|
| dot_zshrc.tmpl, dot_bashrc.tmpl | Zsh와 Fedora 보조 Bash |
| modify_dot_gitconfig + dot_config/git/config.tmpl | identity 보존 + 공통 Git 동작 |
| dot_config/gh/modify_config.yml | gh의 검토한 키만 갱신 |
| dot_config/mise/config*.toml + miserc.toml.tmpl | 공통·AI·Fedora 개인 도구와 기기 선택 |
| dot_tmux.conf.local + symlink_dot_tmux.conf.tmpl | 기존 Oh My Tmux 사용자 설정과 링크 |
| dot_config/nvim | LazyVim 사용자 설정·잠금·선택적 웹 기능 |
| dot_config/shell-completion, dot_config/carapace, dot_local | 기존 Fedora completion 구현·정책·어댑터 |
| private_dot_claude/modify_private_settings.json | Claude theme/tui 선호, 기존 훅 보존 |
| private_dot_codex/modify_private_config.toml | Codex 현재 model/reasoning/service 선호, 나머지 보존 |
| dot_config/opencode/modify_opencode.json | 기존 autoupdate=false |

Git identity와 signing key는 실제 .gitconfig에 남긴다. Git helper만 안정적인 mise shims/gh로 연결하고 빈 reset 항목은 보존한다. 개인 AI 지침과 PowerShell 실제 프로필은 아직 source를 작성하지 않았다.
