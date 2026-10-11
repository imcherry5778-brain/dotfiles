# Mac 적용·검증·복구 기록

2026-10-12에 `ssh mac`의 macOS 27.0.1 Apple Silicon Mac에 적용했다. 저장소 위치는 `~/projects/imcherry5778-brain/dotfiles`다. 적용 코드 `240dbf6`의 전체 hosted CI를 통과시킨 뒤 최신 diff, 변경 대상의 개인 백업, 설치, 설정 적용, 실행 검증, 재실행 순서로 진행했다. 기존 Fedora·Ubuntu·Arch·openSUSE·Windows에는 설치 명령을 다시 실행하지 않았다.

## 실제 설치와 소유권

Homebrew mise를 2026.9.16에서 2026.10.8로 갱신하고 chezmoi 2.73.1을 추가했다. 설치기 Python 3.12.15는 `scripts/unix/mise.toml`에만 선언하고 `mise exec`로 실행한다. 시스템 Python 3.9.6과 기존 Node 24.21.0·pnpm 12.9.1·tmux 3.7c를 보존했다. 전체 업그레이드나 패키지 정리는 실행하지 않았다.

실제 `--version` 실행을 확인한 CLI는 24개다.

| 관리 | 도구와 검증 버전 |
|---|---|
| 공통 mise 13개 | ripgrep 15.2.0, fd 10.4.2, bat 0.26.1, jq 1.8.1, carapace 1.8.0, delta 0.20.1, fzf 0.74.4, zoxide 0.10.0, gh 2.102.0, lazygit 0.66.0, Neovim 0.12.5, Yazi 26.9.1, uv 0.12.23 |
| 공통 AI mise | OpenCode 1.18.35 |
| Mac mise 5개 | Node 24.21.0, pnpm 12.9.1, tmux 3.7c, Pi 1.1.0, Aider 0.86.2 |
| 기존 Homebrew 경로 | agy 1.3.3, Claude 2.1.285, Codex 0.160.0 |
| 검토한 공식 Mac 설치기 | Kiro CLI 2.29.1, Grok 1.0.50 |

Pi는 공식 npm package, Aider는 uv 격리 환경을 사용한다. Kiro·Grok은 저장소에 기록한 SHA256을 확인한 공식 설치기를 사용한다. 기존 Homebrew formula/cask를 삭제하지 않았고 새 항목은 chezmoi와 Orca다. Ghostty 1.3.1·D2Coding은 기존 설치를 유지했고 Orca 1.4.224를 추가했다. mise 자체 갱신과 mise 도구 설치는 별도로 기록했다.

agy는 검증 중 1.2.16에서 1.3.3으로 바뀐 실행 파일이 관측됐다. 설치기는 기존 `/opt/homebrew/bin/agy` 제공자를 보존했으며 agy 갱신 명령을 호출하지 않았다. cask 메타데이터와 실행 파일 버전은 다르므로 최초 버전이 그대로 유지됐다고 보고하지 않는다.

Fedora checkout의 미커밋 OpenCode 1.19.0 변경은 그대로 남겨 두었다. Mac은 검증한 커밋의 1.18.35를 사용한다. 비공개 저장소는 Git bundle로 전달했고 origin은 원래 GitHub HTTPS 주소다. GitHub 인증 정보를 다른 OS에서 복사하지 않았다.

## 설정 보존

Zsh/Oh My Zsh·tmux·LazyVim·Git·CLI와 선택한 AI 키를 chezmoi로 적용했다. Linux용 AI 바이너리·자동완성과 Bash 설정은 Mac 배포에서 제외한다. Mac의 기존 robbyrussell 테마, Hermes `~/.local/bin`, pnpm 전역 경로와 기존 pnpm Node 파일을 유지한다. `.zprofile`의 원래 사용자 내용을 유지하면서 Homebrew shellenv를 추가했다. PATH 중복을 제거하고 mise Node 실행 경로가 먼저 선택되는 것을 확인했다.

유효한 SSH 전달 agent socket을 먼저 사용하며, 없을 때 기존 Bitwarden socket을 사용한다. 이 선택은 실제 Unix socket fixture로 검증했다. Bitwarden 자체 인증이나 SSH 원격 인증을 대신 수행하지 않는다.

Ghostty XDG 설정과 `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`를 함께 검사했다. 기존 D2Coding 설정과 비어 있던 Mac 전용 파일의 바이트를 보존했고 Ghostty의 실제 설정 출력에서 regular/bold/italic/bold-italic D2Coding을 확인했다.

Codex·Claude·GitHub 인증 파일, 기존 pnpm Node 파일, 두 Ghostty 설정은 적용 전후 SHA256이 일치했다. AI 설정의 기존 비관리 키도 유지했다. Orca 시작 후 Orca 소유 Codex hooks 파일과 파생 `hooks.state`가 추가된 것은 별도 확인했다. 기존 hook 값을 삭제하거나 인증 값을 저장소에 넣지 않았다.

## 실제 실행 검증

- 최초 전체 apply와 같은 명령의 재실행이 성공했다. 재실행은 설치된 도구·앱을 재사용했으며 최종 chezmoi diff는 비어 있었다.
- 실제 SSH PTY와 Ghostty Zsh에서 고정 runtime, mise Node 우선순위, PATH 중복 제거, Hermes/pnpm 경로 보존, zoxide·fzf·carapace widgets와 rg/fd/agy completion provider를 확인했다.
- LazyVim을 실제 시작해 33개 플러그인의 설치 HEAD가 `lazy-lock.json`과 일치하는 것을 확인했다.
- 별도 tmux 검증 socket에서 설정과 tmux-resurrect 선택을 확인한 뒤 해당 서버만 종료했다.
- Ghostty 검증용 새 창에서 검사 완료 표시를 실제 화면과 파일로 읽었다. macOS 클립보드 왕복과 Cmd+V로 붙인 검사 문자열을 화면에서 확인했다. 원래 클립보드의 데이터 형식을 Mac 내부에 잠시 보관했다가 복원했고 임시 복사본은 삭제했다.
- Orca 실제 GUI를 확인하고 dotfiles checkout을 등록했다. Orca의 실제 Zsh 터미널에서 AI CLI 8개의 실행 파일 경로와 완료 표시를 읽었다. 사용자 클릭 후 에이전트 설정 화면에서 ‘10개 감지됨’과 요청한 에이전트 선택 항목도 확인했다. 검증용 터미널만 닫았고 AI 질의나 유료 API 호출은 하지 않았다.

Orca Computer Use의 macOS 손쉬운 사용·화면 녹화 권한은 사용자가 직접 허용했다. 최초에는 권한 조회가 허용 상태를 보고하면서 실제 접근은 거부했으며, 사용자가 해당 손쉬운 사용 항목을 껐다 켠 뒤 Ghostty·Orca 화면 캡처가 정상화됐다. Orca 자체 창의 좌표 클릭에는 이 버전의 focus 판정 제한이 남아 있어 사용자 클릭으로 탐지 화면을 확인했다. 서비스별 로그인·토큰 유효성은 설치 성공과 별개이며 자동 로그인이나 인증 이전은 수행하지 않았다.

## 개인 백업과 복구

Mac 내부의 첫 적용 백업:

```text
~/.local/state/dotfiles/backups/20261011T203249.926267Z-macos
```

재실행 직전 백업:

```text
~/.local/state/dotfiles/backups/20261011T204136.245233Z-macos
```

각 디렉터리는 0700이고 manifest·diff·복원 안내는 0600이다. 변경 대상 파일만 `files/` 아래에 권한과 symlink를 보존해 저장했다. 디렉터리 항목은 권한 메타데이터만 기록하며 전체 내용을 복사하지 않는다. 검증·설치 로그와 추가 설치 목록은 `~/.local/state/dotfiles/review/macos/`에 남겼다. 이 개인 기록은 Git에 넣지 않는다.

복구할 때 먼저 manifest와 백업 이후의 사용자 변경을 비교한다. `exists=true`인 파일만 `files/`에서 원래 경로로 권한·symlink를 보존해 복사하고, 디렉터리는 기록된 mode만 복원한다. `exists=false`는 설치 전에 없던 관리 대상이므로 해당 파일과 비어 있는 관리 디렉터리만 제거할 수 있다. 홈 전체를 덮어쓰거나 비어 있지 않은 디렉터리를 삭제하지 않는다. 이 절차는 설정 복원이며 설치 바이너리를 제거하지 않는다. 추가 도구 제거가 필요하면 개인 `installation-additions.json`과 설치 출처를 확인해 개별적으로 처리한다.

## 저장소와 hosted CI 결과

설치 진입점은 기본 plan/check에서 설치하지 않는다. Linux/Mac은 mise 관리 Python으로, Windows는 PowerShell 5.1에서 PowerShell 7을 준비한 뒤 같은 인자로 이어 실행한다. Windows 5.1과 7의 실행 정책 저장 위치를 구분하며 기본 Windows 5.1 정책은 바꾸지 않는다. 최초 Windows 인계에는 프로세스 범위 Bypass를 사용하고 이후의 PS7 프로필 실행을 별도 새 프로세스로 확인한다. Mac은 Homebrew를 직접 사용하며 Arch·openSUSE의 기존 패키지 보호 로직을 유지한다.

코드 `240dbf6`에 대해 다음 결과를 확인했다. Self-hosted runner는 없다.

- [Installation checks: 7개 작업 성공](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38172173822): Fedora·Ubuntu baseline, Ubuntu·Arch·openSUSE full, Windows native CLI, Mac ARM64 full.
- [Foundation checks: 3개 OS 성공](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38172173829): 구문·격리 렌더링·실행 계약·이전 다섯 프로필 회귀 검사.

최초 설치·재실행·공백 경로·기존 설정 보존·다운로드 실패·출처 충돌을 테스트했다. 기존 다섯 프로필의 배포 결과와 제공자 선언은 의도한 변경 외에는 같아야 한다. hosted 검증은 실제 데스크톱 권한·클립보드·서비스 인증 성공을 뜻하지 않으며 위 Mac 기기 검증과 구분한다.

공식 근거: [mise bootstrap](https://mise.jdx.dev/bootstrap/packages/), [Homebrew와 mise 소유권 차이](https://mise.jdx.dev/bootstrap/packages/brew.html), [Kiro 설치](https://kiro.dev/docs/getting-started/installation/), [Grok 공식 CLI](https://docs.x.ai/build/overview), [Ghostty 설정 위치](https://ghostty.org/docs/config).
