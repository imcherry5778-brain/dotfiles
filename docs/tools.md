# 도구와 선택 환경

## 합의한 범위

일반 CLI 13개: ripgrep, fd, bat, jq, fzf, zoxide, gh, lazygit, delta, neovim, yazi, uv, carapace.

AI CLI 8개: agy, claude, codex, aider, opencode, pi, kiro-cli, grok.

Unix는 Zsh + Oh My Zsh, 기존 tmux와 LazyVim 설정을 사용한다. Linux/macOS 터미널은 Ghostty, Windows는 PowerShell 7 + Windows Terminal을 사용한다. GUI 에이전트 관리에는 Orca를 사용한다. Windows에 WSL을 필수 설치하지 않는다.

이 목록은 도입 범위이지 현재 설치 선언이나 모든 플랫폼의 실행 검증 결과가 아니다. 프로그램 버전을 저장소에 선언하는 단계에서 기존 실행 버전과 공급자를 다시 확인한다. 초기 저장소 변경에 CLI 업그레이드를 섞지 않는다.

## 설치 주체

지원되는 CLI는 mise를 우선 사용한다. Aider는 초기 이전에서 기존 uv 독립 환경을 보존하고 Kiro는 공식 설치 방식을 유지하는 예외로 계획한다. 해당 설치/검증 작업은 향후 mise 작업에서 연결한다. 도구 자체 updater와 mise가 같은 설치를 동시에 관리하지 않도록 검증한다.

기반 패키지는 OS 패키지 공급자가 담당한다. 최초 Git·mise·chezmoi 확보와 공통 CLI 설치 선언을 구분한다. 선택한 CLI 실행에 필요한 런타임만 해당 도구 범위에서 다루며 모든 개발 SDK·클라우드 도구·Conda를 모든 OS에 설치하지 않는다.

## 미래 mise 환경 매핑

| 기기 | 선택 환경 계획 |
|---|---|
| 기존 Fedora | unix, ai, fedora, personal-fedora |
| 새 Ubuntu | unix, ai, ubuntu |
| Arch | unix, ai, arch |
| openSUSE Tumbleweed | unix, ai, opensuse |
| macOS | unix, ai, macos |
| Windows | ai, windows |

personal-fedora는 기존 추가 도구 보존 선택이며 모든 Fedora의 기본값이 아니다. OS ID opensuse-tumbleweed와 환경 이름 opensuse를 구분한다. 환경 선택은 miserc.toml에서 명시하고, 실제 config/lock 생성 결과를 검증한다. 현재 루트 mise.toml에는 plan/check 작업만 있다.
