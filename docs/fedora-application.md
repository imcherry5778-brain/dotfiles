# 개인 Fedora 적용 기록

2026-10-11, 사용자 승인 후 코드 commit `3d48e5d`를 실제 Fedora 44 홈에 적용했다. GitHub-hosted CI 실행과 개인 기기 실행은 별도다. 같은 코드의 [Installation checks](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38138603725)와 [3개 OS Foundation checks](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38138603686)가 통과했다.

## 최신 diff와 적용 범위

개인 프로필의 관리 파일/링크 477개 중 기존 변경 13개·새 파일 4개·내용 동일 460개를 적용 직전 다시 확인했다. 별도로 .claude/.codex/gh 디렉터리를 700, Claude settings를 600으로 제한했다. .local/share의 기존 700은 유지했다. 변경·생성 대상 원본과 원래 권한을 비공개 대상별 복구본에 기록했다.

- Zsh/Bash, 공통 Git include와 gh 인증 helper, mise inventory·선택, tmux 사용자 설정, 기존 Neovim 설정을 관리한다.
- common 13개·AI 1개·personal-fedora 20개를 선택한다. 없던 ripgrep/fd/bat/jq/carapace/delta 6개만 설치했으며 기존 28개 버전과 실제 설치 경로는 유지했다. RPM 도구는 남겼다.
- 수동 carapace를 ~/.local/bin/carapace → mise shim으로 연결했다. 새 binary와 원래 binary의 SHA-256이 동일하다. 기존 Bash/스크립트 호출 경로를 유지한다.
- AI 설정 세 파일과 gh config는 원문 그대로다. 인증 파일·SSH config/known_hosts의 내용·권한은 그대로다. Git identity·서명 정책도 유지한다.
- OMZ와 tmux 자동 갱신을 끄고 CLI 버전을 고정했다. 기존 vendor/plugin checkout과 TPM 로컬 패치를 유지하므로 externals=false다. delta pager는 false이며 기존 Git pager를 유지한다.
- Conda/Mamba, Bitwarden agent, agy workaround, 자동완성 정책, 기존 LazyVim은 유지한다. 파티션·GRUB·VM과 다른 OS는 범위 밖이다.

## 실제 기기 검증

chezmoi apply 후 verify가 통과하고 diff가 비었다. 총 34개 도구가 설치·선택된 것을 확인하고 공통 13개 실행 경로·버전을 실제로 확인했다. 네트워크를 차단한 읽기 전용 host namespace에서 별도 PTY/캐시를 사용해 Zsh 14개 플러그인, alias·키·history, GPG_TTY, Conda/Mamba·agent socket, fzf/zoxide와 mise 경로를 검사했다. Zsh completion 2,424개와 Bash completion 520개는 이전과 동일했다. 기존 Neovim에서 LazyVim과 nvim-lspconfig를 로드한 headless startup도 통과했다.

적용 전 별도 tmux socket에서 기존·제안 설정의 플러그인/키/옵션을 비교했고 적용 후 별도 서버의 플러그인 바인딩·마우스 설정도 확인했다. CLI 26개의 native completion을 임시 캐시에서 생성해 적용 전 결과와 SHA-256이 동일함을 확인했다. 실제 GitHub helper로 저장소 읽기 접근도 성공했다. 실제 GUI 클립보드나 인증이 필요한 서비스 동작, 모든 CLI의 Tab UI, 모든 LSP 서버는 전수 검사하지 않았다. 검증 때 로그인 데이터와 관리 파일이 변경되지 않았는지도 확인했다.

## 이 기기의 이후 설정 관리

실제 기기 선택은 ~/.config/chezmoi/chezmoi.toml에 보존한다. deployment.enabled=true, externals=false이며 personal_fedora·ai·conda·bitwarden_agent·editor_web은 true, delta는 false다. sourceDir는 이 checkout을 가리키고 home이 배포 소스다.

```sh
cd "$HOME/projects/imcherry5778-brain/dotfiles"
git pull --ff-only
chezmoi diff --exclude=scripts
# 변경을 검토한 뒤 (활성화된 자동화가 대상별 백업을 준비한다):
chezmoi apply
chezmoi verify --exclude=scripts
```

2026-10-12에 [개인 Fedora 자동화 이행](fedora-automation.md)을 완료했다. 현재는 일반 chezmoi apply가 선택된 mise 버전의 누락 복구와 실행 검증을 수행하므로 mise install을 따로 실행할 필요가 없다. Native AI·Conda·앱의 기존 공급자는 유지한다. 셸 시작과 Actions는 개인 PC를 자동 갱신하지 않는다. 기존 개인 환경에 tests/profiles/fedora-common.json을 적용하면 안 된다. 새 terminal은 새 셸 설정을 읽는다. 이미 열린 셸/앱은 강제 종료하지 않았다. tmux의 기존 세션은 유지하고 필요하면 해당 세션에서 설정을 다시 읽는다.

복구 범위와 명령은 [복구 계약](restore.md)을 따른다. 다른 OS의 init/fixture 통과는 그 기기에 실사용 설정을 적용했다는 의미가 아니다.
