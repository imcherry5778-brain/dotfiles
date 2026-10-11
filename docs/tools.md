# 도구와 선택 환경

합의한 공통 CLI는 ripgrep, fd, bat, jq, fzf, zoxide, gh, lazygit, delta, neovim, yazi, uv, carapace 13개다. AI 범위는 agy, claude, codex, aider, opencode, pi, kiro-cli, grok이다.

현재 구성은 Fedora 설치 현황에서 확인된 버전을 기준으로 한다. [inventory](fedora-inventory.json)를 참고한다. source에는 공통 13개·기존 OpenCode 1개·개인 Fedora 도구 20개를 별도 환경으로 선언했고 중복 소유권을 검사했다. 기존 aws-cli 옵션도 유지한다.

`config.toml`은 공통, `config.ai.toml`은 기존 mise-owned AI, `config.personal-fedora.toml`은 개인 추가 도구다. `miserc.toml`에서 ai/personal-fedora를 명시적으로 선택한다. 빈 OS 환경 파일은 만들지 않는다. 향후 다른 OS의 실제 패키지 차이가 생길 때 필요한 config.<environment>.toml만 추가한다.

개인 Fedora에서 ripgrep/fd/bat/jq/carapace/delta 6개를 선언한 고정 버전으로 설치했다. 공통 13개를 포함한 총 34개 도구의 선택·설치·실행 경로를 확인했고 기존 28개의 버전·설치 경로는 유지했다. RPM rg/fd/bat/jq는 fallback으로 남겼다. ~/.local/bin/carapace는 mise shim 링크이며 원래 수동 바이너리는 복구본에 보존했다. delta CLI는 설치했지만 features.delta=false라 Git pager는 유지한다. OS별 artifact/checksum이 포함된 전체 mise lockfile은 아직 없다.

SDK·클라우드·Conda는 다른 OS의 기본 설치로 확대하지 않는다. Fedora 개인 기능 선택도 명시적이며 새 Fedora에 자동 활성화하지 않는다. Git·mise·chezmoi·셸·tmux 등 기반 패키지는 OS 공급자의 책임이다. root mise.toml은 plan/check 작업만 가지며 global tool inventory를 중복하지 않는다.

Windows는 PowerShell 7 + 기존 Windows Terminal, Unix는 Zsh + Oh My Zsh와 Ghostty를 사용한다. Windows 프로필은 공통 CLI 버전을 재사용하되 WinGet 우선으로 공급자를 선택한다. 자세한 공급자·Windows 등록 버전 예외·mise fallback은 [Windows 구성](windows.md)에 있다. WSL은 필수가 아니며 macOS 실제 적용은 별도 단계다.

Ubuntu는 ai/editor-ubuntu 환경을 명시적으로 선택한다. config.editor-ubuntu.toml은 선택한 LazyVim 웹 기능에 필요한 Node/npm만 소유한다. Fedora의 Node는 기존 personal-fedora inventory에 남으며 Ubuntu 전용 파일은 Fedora에서 제외된다. Ubuntu 기본 선택은 공통 13개 + OpenCode + Node = 15개다. 기존 Ubuntu baseline은 15개를 유지한다. ubuntu-full profile은 managed_ai/desktop을 명시적으로 켜서 추가 AI 7개를 포함한 mise 22개 CLI와 native Ghostty·Orca를 설치한다. Fedora에는 새 AI 공급자를 선택하지 않는다. [설치 자동화 계약](installation-automation.md)을 참고한다.

Arch는 Ubuntu와 같은 CLI 버전 목록을 재사용한다. Arch의 Node 환경 파일 이름은 `editor-web`이고 Ubuntu는 기존 `editor-ubuntu`를 유지한다. Node 버전 선언은 공통 템플릿 한 곳에서 관리한다. Arch full 22개 CLI와 앱의 실제 적용 결과는 [Arch 적용 기록](arch-application.md)에 있다.
