# 플랫폼과 검증 수준

| 대상 | OS 판정 값 | 현재 검증 범위 |
|---|---|---|
| Fedora | fedora / linux | 개인 홈 적용·verify; 39개 도구 선택, 실제 PTY Zsh/Bash·기존 LazyVim/LSP 시작·native completion 보존; Fedora 44 컨테이너 baseline 설치·Zsh/tmux 반복 검증 |
| Ubuntu | ubuntu / linux | 개인 Ubuntu 26.04.1 홈에 22개 CLI·Ghostty·Orca 적용; Bash 자동완성 150개 보존, 반복 apply·verify, 실제 Ptyxis/Zsh·Wayland 클립보드·LazyVim 33개 플러그인 잠금 버전 검증; Ubuntu 26.04 컨테이너 설치도 통과 |
| Arch | arch / linux | 개인 홈 22개 CLI·Ghostty·Orca 적용; 기존 패키지·Bash/KDE/입력기 보존, Zsh/tmux·반복 설치·Wayland clipboard·LazyVim lock·GUI 검증; hosted Arch full 설치 통과 |
| openSUSE Tumbleweed | opensuse-tumbleweed / linux | 개인 홈 22개 CLI·Ghostty·Orca 적용, 기존 RPM/Bash/profile/KDE 보존·Zsh/tmux·LazyVim lock·반복 설치 검증; hosted full 설치·실제 KDE Wayland Ghostty/Orca GUI·클립보드 검증 통과 |
| macOS | macos / darwin | 개인 ARM64 Mac 24개 CLI·Ghostty·Orca·Zsh·LazyVim lock·클립보드·반복 적용 검증; hosted ARM64 full 설치 성공 |
| Windows | windows / windows | 개인 Windows 11 native CLI·Orca GUI 검증 완료; PowerShell 5.1 시작·PS7 인계·새 PS7 프로필 실행·반복 적용 hosted CLI 설치 검증 성공 |

Foundation checks는 구문·격리 렌더링·초기화·배포 경계·경로 처리를 확인한다. Installation checks는 별도로 Fedora 44 common baseline 13개, Ubuntu 26.04 desktop CLI 15개, Fedora·Ubuntu·Arch·openSUSE full CLI 22개와 Ghostty·Orca 설치·실행과 Zsh/tmux·반복 적용, Windows native CLI, Mac ARM64 24개 CLI 설치를 확인한다. 어느 쪽도 로그인·SSH/GPG·클립보드·GUI·Neovim 플러그인 설치·모든 배포판 호환성 완료를 의미하지 않는다.

현재 실사용 configuration source는 Fedora·Ubuntu·Arch·openSUSE·Windows·Mac에 적용했다. 실제 기기 검증은 hosted CI와 별개다. 다른 OS의 기반 init/plan/check가 성공했다고 그 OS에 Fedora 설정을 배포하지 않는다. 모든 플랫폼은 명시적 enabled 선택이 필요하다. Windows/Mac은 추가 native opt-in으로 배포 경계를 유지한다.

각 OS는 자기 사용자 홈에 독립 checkout을 둔다. 경로 예시는 Linux /home/<user>/projects/imcherry5778-brain/dotfiles, macOS /Users/<user>/projects/imcherry5778-brain/dotfiles, Windows의 실제 $HOME 아래 projects/imcherry5778-brain/dotfiles다.

FreeBSD는 이번 자동화 대상에서 제외한다. 기존 FreeBSD 설치·VM은 이 저장소 구축과 무관하게 유지한다. 파티션·GRUB·VM·디스크 공유 훅은 변경 범위에 포함하지 않는다.
