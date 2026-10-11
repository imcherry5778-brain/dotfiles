# 최초 설치 계약

기본 실행은 계획 출력이며 설치하지 않는다. `--apply`/`-Mode Apply`에서만 실제 홈을 변경한다. 지원 범위는 Fedora 44, Ubuntu 26.04, Arch, openSUSE Tumbleweed의 x86_64, Windows 11 x64, Apple Silicon macOS다. FreeBSD는 제외한다.

## Checkout

이 저장소는 private다. Git 설치와 저장소 접근 권한을 먼저 준비한다. 인증은 기기별 설정을 사용하며 저장소에 토큰을 넣지 않는다. 기존 checkout을 새 clone으로 덮어쓰지 않는다.

```sh
git clone https://github.com/imcherry5778-brain/dotfiles.git "$HOME/projects/imcherry5778-brain/dotfiles"
cd "$HOME/projects/imcherry5778-brain/dotfiles"
sh install.sh --plan
```

Windows는 실제 `$HOME` 아래 같은 상대 경로를 사용한다. 기본 PowerShell 5.1에서 시작할 수 있다. WinGet이 없다면 Microsoft App Installer를 설치/갱신한 뒤 실행한다. 관리자 암호·UAC·앱 권한은 사용자가 처리한다.

## 하나의 명시적 설치 명령

| 환경 | 명령 |
|---|---|
| 새 Fedora 공통 구성 | `sh install.sh --apply --profile tests/profiles/fedora-common.json` |
| Ubuntu 전체 | `sh install.sh --apply --profile tests/profiles/ubuntu-full.json` |
| Arch 전체 | `sh install.sh --apply --profile tests/profiles/arch-full.json` |
| openSUSE 전체 | `sh install.sh --apply --profile tests/profiles/opensuse-tumbleweed-full.json` |
| Mac 전체 | `sh install.sh --apply --profile tests/profiles/macos-full.json` |
| Windows 전체 | `./install.ps1 -Mode Apply -ProfilePath tests/profiles/windows-full.json` |

Fedora common은 공통 13개 CLI만 선택한다. 기존 개인 Fedora의 AI/Conda/개인 도구 선택을 대체하는 프로필이 아니다. Ubuntu/Arch/openSUSE의 desktop 프로필은 15개 CLI, full은 22개 CLI와 앱을 선택한다. Mac은 19개 mise 도구와 native AI 5개를 검증한다. Windows CLI-only 프로필은 hosted CI에서 GUI 설치를 제외하기 위해 사용한다. Windows Ghostty는 공식 native 배포가 없어 Windows Terminal을 유지한다.

## 실행 순서와 소유권

1. 실제 일반 사용자 홈·OS/architecture·프로필·기존 선택·기본 config 경로를 확인한다. HOME/XDG를 임의로 바꿔 적용하지 않는다.
2. 필수 도구를 준비한다. Linux/Mac 설치기 Python 3.12.15는 `scripts/unix/mise.toml`로 설치해 `mise exec`로 실행한다. 시스템 Python을 교체하지 않는다. Windows 5.1 진입점은 필요한 PowerShell 7을 WinGet으로 준비한 뒤 같은 인자로 이어 실행한다.
3. OS 필수 패키지를 설치한다. Ubuntu/Fedora는 standalone mise bootstrap packages로 누락분만 추가한다. Arch는 기존 sync DB를 쓰고 단독 `-Sy`를 호출하지 않는다. DB가 없으면 전체 `pacman -Syu` 준비를 안내하고 중단한다. openSUSE는 기존 solver를 검사해 추가만 허용한다. Mac은 Homebrew를 직접 사용한다.
4. 현재 설정을 다시 읽고 fresh diff를 출력한다. 변경 대상만 개인 백업한다. Unix 백업은 `~/.local/state/dotfiles/backups/<timestamp>-<platform>`이며 파일 권한·symlink·원래 없던 경로를 기록한다. Windows는 같은 위치에 대상 파일과 사용자 PATH/정책 값을 기록한다.
5. 선택한 CLI와 앱을 설치한다. chezmoi는 설정, mise는 CLI 버전, 각 OS provider는 필수 패키지/GUI를 소유한다. 기존 native 앱/provider를 자동 이전하거나 업그레이드하지 않는다. Mac의 bootstrap mise가 최소 버전 미만이면 기존 Homebrew owner로 해당 도구만 갱신한다.
6. 설정을 적용하고 `chezmoi verify`·diff·CLI 실행을 확인한다. 같은 명령 재실행은 누락분을 보완한다. 전체 업그레이드·prune·다른 provider 삭제는 하지 않는다.

Mac의 최초 Homebrew 설치에는 Apple Command Line Tools와 관리자 입력이 필요하다. 이미 있는 Ghostty/D2Coding/agy/Claude/Codex와 mise Node·pnpm·tmux 버전을 보존한다. Bitwarden socket은 유효한 전달 agent socket이 없는 경우에만 사용한다. 자세한 Mac 경로/보존 규칙은 [Mac 적용 기록](macos-application.md)에 있다.

네트워크·체크섬·선택 충돌은 실패로 보고한다. 설치 전체의 자동 rollback은 제공하지 않는다. 백업의 `manifest.json`, `before.diff`, `RESTORE.md`로 설정 복원 범위를 확인한다. 새 앱/바이너리는 설정 백업과 구분하며 provider에서 별도로 제거한다. 서비스 인증·SSH 개인키·Conda·기본 셸 전환·GUI 권한은 자동 복제하지 않는다.

## Hosted CI와 실제 기기

Foundation은 격리 렌더링·구문·기존 설정 보존·다운로드 실패 계약을 검사한다. Installation은 네 Linux의 최소 컨테이너와 Windows/Mac hosted 환경의 실제 홈에서 최초 설치와 재실행, 공백 checkout, CLI 실행, 셸/기존 설정 보존을 검사한다. Linux 컨테이너의 root 단계에는 clone/network/admin 필수 패키지만 둔다. Mac은 ARM64, Windows는 5.1 시작 경로를 사용한다.

CI의 성공은 개인 GUI·클립보드·서비스 인증의 성공을 뜻하지 않는다. 실제 Mac의 Ghostty·Orca·자동완성·편집기·Orca CLI 탐지는 별도 검증한다. 기존 다섯 OS에는 이번 설치기를 재실행하지 않는다.

## 확인한 실행 결과

2026-10-11, 코드 commit `c566f13`의 [Installation checks](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38137704512)가 통과했다. Fedora 44 일반 사용자에서 13개 CLI를 새로 설치하고 모든 실행 파일의 실제 경로·버전을 확인했다. Zsh/tmux runtime와 Neovim Lua 구문 검사 후 같은 진입점을 재실행했고, external 파일을 포함한 managed 경로 1,902개의 내용·링크·권한이 동일하며 chezmoi diff가 비어 있음을 확인했다.

같은 commit의 [Foundation checks](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38137704539)도 Linux·Windows·macOS에서 통과했다. Windows/macOS의 실제 도구 설치 성공을 의미하지 않는다. 당시 실제 Fedora 사용자 홈의 검토 기준 476개 경로와 기존 파일 449개는 변경되지 않았다. 이후 개인 홈 적용 기록은 [Fedora 실제 적용 결과](fedora-application.md)에서 구분한다.

2026-10-11, Ubuntu 지원 코드 commit `55f5402`의 [Installation checks](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38140944752)는 Ubuntu 26.04의 15개 도구와 Fedora 44의 13개 도구를 각각 새로 설치해 두 번 적용했다. 두 환경 모두 실행 경로/버전·Zsh/tmux·기존 설정 보존·반복 적용·빈 diff를 통과했다. 관리 경로는 external을 포함하여 Ubuntu 1,944개·Fedora 1,903개다. 당시 Ubuntu 사용자 홈은 미적용이었으며 이후 실제 적용 결과는 [Ubuntu 적용 기록](ubuntu-application.md)에 있다.
