# 플랫폼과 검증 수준

| 대상 | OS 판정 값 | 현재 검증 범위 |
|---|---|---|
| Fedora | fedora / linux | 개인 홈 적용·verify; 34개 도구 선택, 실제 PTY Zsh/Bash·기존 LazyVim/LSP 시작·native completion 보존; Fedora 44 컨테이너 baseline 설치·Zsh/tmux 반복 검증 |
| Ubuntu | ubuntu / linux | 개인 Ubuntu 26.04.1 홈에 15개 CLI·설정 적용; Bash 자동완성 150개 보존, 반복 apply·verify, 실제 Ptyxis/Zsh·Wayland 클립보드·LazyVim 33개 플러그인 잠금 버전 검증; Ubuntu 26.04 컨테이너 설치도 통과 |
| Arch | arch / linux | fixture만; pacman·데스크톱 미검증 |
| openSUSE Tumbleweed | opensuse-tumbleweed / linux | fixture만; Zypper·데스크톱 미검증 |
| macOS | macos / darwin | fixture와 CI의 기반 검사; 실제 기기 미검증 |
| Windows | windows / windows | fixture와 CI의 PowerShell 기반 검사; 실제 기기 미검증 |

Foundation checks는 구문·격리 렌더링·초기화·배포 경계·경로 처리를 확인한다. Installation checks는 별도로 Fedora 44 common baseline 13개 및 Ubuntu 26.04 desktop CLI 15개 설치·실행과 Zsh/tmux·반복 적용을 확인한다. 어느 쪽도 로그인·SSH/GPG·클립보드·GUI·Neovim 플러그인 설치·모든 배포판 호환성 완료를 의미하지 않는다.

현재 실사용 configuration source는 Fedora와 Ubuntu에 적용했다. [Fedora 실제 기기 검증](fedora-application.md)과 [Ubuntu 실제 기기 검증](ubuntu-application.md)은 hosted CI와 별도로 기록한다. 다른 OS의 기반 init/plan/check가 성공했다고 그 OS에 Fedora 설정을 배포하지 않는다. `.chezmoiignore`가 Fedora/Ubuntu 외 대상 전체를 제외하며 두 플랫폼도 명시적 enabled 선택이 필요하다.

각 OS는 자기 사용자 홈에 독립 checkout을 둔다. 경로 예시는 Linux /home/<user>/projects/imcherry5778-brain/dotfiles, macOS /Users/<user>/projects/imcherry5778-brain/dotfiles, Windows의 실제 $HOME 아래 projects/imcherry5778-brain/dotfiles다.

FreeBSD는 이번 자동화 대상에서 제외한다. 기존 FreeBSD 설치·VM은 이 저장소 구축과 무관하게 유지한다. 파티션·GRUB·VM·디스크 공유 훅은 변경 범위에 포함하지 않는다.
