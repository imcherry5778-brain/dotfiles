# 도구와 선택 환경

합의한 공통 CLI는 ripgrep, fd, bat, jq, fzf, zoxide, gh, lazygit, delta, neovim, yazi, uv, carapace 13개다. AI 범위는 agy, claude, codex, aider, opencode, pi, kiro-cli, grok이다.

현재 구성은 Fedora 설치 현황에서 확인된 버전을 기준으로 한다. 현재 source에는 공통 13개·OpenCode 1개·개인 Fedora 도구 25개를 별도 환경으로 선언해 총 39개를 관리한다. 기존 aws-cli 옵션도 유지한다. 2026-10-26에 수동 설치 k3d·Argo CD CLI·cosign·ORAS를 같은 버전으로 mise에 편입했다. chezmoi는 DNF, mitmproxy는 uv가 소유한다.

`config.toml`은 공통, `config.ai.toml`은 모든 OS가 공유하는 OpenCode 2.x(aqua 바이너리 별칭 포함), `config.personal-fedora.toml`은 개인 추가 도구다. `miserc.toml`에서 ai/personal-fedora를 명시적으로 선택한다. 빈 OS 환경 파일은 만들지 않는다. 향후 다른 OS의 실제 패키지 차이가 생길 때 필요한 config.<environment>.toml만 추가한다.

개인 Fedora의 RPM rg/fd/bat/jq는 fallback으로 남긴다. ~/.local/bin/carapace는 mise shim 링크다. delta CLI는 설치하지만 features.delta=false라 Git pager는 유지한다. OpenCode는 `mise.ai.lock`에 Linux x64/ARM64와 macOS x64/ARM64의 release URL·SHA-256을 기록하고 설치 시 해당 도구만 `--locked`로 검사한다. Windows는 별도로 검토한 release checksum을 같은 버전의 GitHub backend 옵션으로 렌더링한다. 다른 도구의 갱신 정책은 유지한다. 개인 Fedora의 Ansible 2.21.5는 Python 3.15와 호환되지 않아 Python 3.14 격리 환경을 명시한다.

SDK·클라우드·Conda는 다른 OS의 기본 설치로 확대하지 않는다. Fedora 개인 기능 선택도 명시적이며 새 Fedora에 자동 활성화하지 않는다. Git·mise·chezmoi·셸·tmux 등 기반 패키지는 OS 공급자의 책임이다. root mise.toml은 plan/check 작업만 가지며 global tool inventory를 중복하지 않는다.

Windows는 PowerShell 7 + 기존 Windows Terminal, Unix는 Zsh + Oh My Zsh와 Ghostty를 사용한다. Windows 프로필은 공통 CLI 버전을 재사용하되 WinGet 우선으로 공급자를 선택한다. 자세한 공급자·Windows 등록 버전 예외·mise fallback은 [Windows 구성](windows.md)에 있다. WSL은 필수가 아니다.

Ubuntu는 ai/editor-ubuntu 환경을 명시적으로 선택한다. config.editor-ubuntu.toml은 선택한 LazyVim 웹 기능에 필요한 Node/npm만 소유한다. Fedora의 Node는 기존 personal-fedora inventory에 남으며 Ubuntu 전용 파일은 Fedora에서 제외된다. Ubuntu 기본 선택은 공통 13개 + OpenCode + Node = 15개다. 기존 Ubuntu baseline은 15개를 유지한다. ubuntu-full profile은 managed_ai/desktop을 명시적으로 켜서 추가 AI 7개를 포함한 mise 22개 CLI와 native Ghostty·Orca를 설치한다. 기존 개인 Fedora의 공급자는 보존한다. 새 Fedora portable full은 managed AI와 editor-web 환경을 선택해 같은 22개 CLI와 Ghostty·Orca를 준비한다. [설치 자동화 계약](installation-automation.md)을 참고한다.

Arch는 Ubuntu와 같은 CLI 버전 목록을 재사용한다. Arch의 Node 환경 파일 이름은 `editor-web`이고 Ubuntu는 기존 `editor-ubuntu`를 유지한다. Node 버전 선언은 공통 템플릿 한 곳에서 관리한다.

OpenCode 버전을 올릴 때는 공통 pin과 두 checksum 원본을 함께 갱신한다. 격리된 임시 디렉터리에서 `config.ai.toml`을 `mise.toml`로 복사하고 `mise lock opencode --platform linux-x64,linux-arm64,macos-x64,macos-arm64`로 만든 lock을 `home/dot_config/mise/mise.ai.lock`에 반영한다. 별도 임시 디렉터리에 같은 버전의 `"github:anomalyco/opencode"`만 선언한 뒤 `mise lock github:anomalyco/opencode --platform windows-x64`로 만든 lock을 `home/.chezmoitemplates/tools/opencode-windows.lock`에 반영한다. 릴리스의 `SHA256SUMS`와 각 checksum을 대조하고 회귀 기준을 검토한다. `tests/verify-installers.py`는 두 lock과 공통 버전의 일치·플랫폼별 checksum·다른 도구의 미포함을 검사한다. Windows 템플릿과 Unix locked 설치는 오래되거나 빠진 pin을 자동으로 우회하지 않는다.
