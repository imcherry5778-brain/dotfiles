# openSUSE Tumbleweed KDE 적용

## 적용 전 분석과 변경 판단

기존 `imcherry` 사용자 셸은 Bash다. `.bashrc`와 `.profile`은 SUSE 기본 파일이고, 선택한 mise·chezmoi·Zsh·Neovim·AI CLI 설정은 없었다. 기존 KDE·fcitx5·환경 변수 파일은 배포 대상에서 제외했다. 원본 Bash 파일 전체를 남기고 마지막에 공통 셸 모듈 호출 한 번만 추가한다. `.profile`과 `.alias`의 기존 호출 방식을 유지한다. 관리 대상 파일 30개의 diff와 원래 없던 경로를 실제 홈 기준으로 확인한 뒤 백업했다.

CLI 버전은 기존 Ubuntu/Arch의 단일 mise inventory를 재사용한다. 공통 CLI 13개와 AI CLI 8개, Node로 총 22개다. Node 선언은 같은 공통 template에서 `editor-web`으로 렌더링하며 Ubuntu의 기존 `editor-ubuntu` 이름은 유지한다. AI 인증·세션·사용자가 만든 이력은 복사하지 않는다.

- Ghostty: [공식 설치 문서](https://ghostty.org/docs/install/binary)의 openSUSE OSS 패키지. 빈 사용자 설정을 배포하지 않는다.
- Orca: [공식 Linux 설치](https://www.onorca.dev/docs/install)의 1.4.224 AppImage를 SHA-256 검증하고 사용자 경로에 푼다. Arch와 같은 원본 AppRun·번들 CLI·메타데이터를 공유하며 별도 npm CLI나 비공식 RPM을 사용하지 않는다. 이 설치의 갱신은 새 공식 릴리스 검토 후 별도로 수행한다.
- OS 패키지: 기존 저장소 메타데이터를 유지하며 Zypper dry-run의 순수 추가 계획만 실행한다. 기존 RPM 제거·upgrade·downgrade·vendor 변경과 서명 검사 우회를 허용하지 않는다.

## 백업과 실제 적용

개인 openSUSE 백업은 `~/.local/state/dotfiles/backups/20261011T144027Z`다. 원본 Bash/profile, 원래 없던 설정 목록, 초기 로그인 셸, 패키지 목록, 기존 KDE·입력기 등 설정 해시, 적용 전 diff를 담는다. 디렉터리 700·파일 600이고 저장소에는 개인 백업을 넣지 않는다.

2026-10-11부터 12일까지 `Desktop / openSUSE · KDE`가 사용하는 실제 물리 파티션의 사용자 홈에 적용했다. 기본 QGA는 command execution을 비활성화하며 SELinux로 제한한다. 그 정책을 유지하고 VM 종료 상태에서 실제 openSUSE userland를 사용해 사용자 권한으로 설치했다. 호스트 kernel을 사용하는 오프라인 검증과 실제 KDE 부팅 검증을 구분한다. 오프라인 작업용 resolver는 원래 symlink로 복원했다.

기존 RPM 2,125개의 이름·버전이 모두 같고 필수 OS 패키지 38개만 추가했다. Ghostty는 1.3.1-2.1, Orca는 1.4.224다. 설정 배포 직후 `.profile`과 KDE·fcitx5·환경 설정 16개 해시가 일치한다. 실제 GUI 검증 후에는 15개가 동일하고 `kwinrc`만 KDE 세션 실행 후 해시가 달라졌다. KWin 설정은 배포 대상에서 제외하며 실행 후 변경된 파일을 덮어쓰거나 복원하지 않았다. SUSE Bash 별칭 20개와 history 정책을 유지했고 bash-completion 설치 후의 native handler 137개도 공통 설정 적용 후 모두 유지했다. `.bashrc` 권한은 관리 계약에 따라 640에서 600으로 바꿨다.

설치 진입점은 로그인 셸을 바꾸지 않는다. 기기 마무리 단계에서 `/etc/shells`를 확인하고 실제 `imcherry` 계정만 `/bin/bash`에서 `/usr/bin/zsh`로 전환했다. 기존 Bash는 원문을 유지해 별도로 사용할 수 있다.

## 검증 결과와 남은 경계

- 고정된 CLI 22개의 실제 mise 경로·버전·실행을 확인했다.
- 실제 PTY의 Zsh/Oh My Zsh 플러그인 11개와 tmux 플러그인 바인딩을 확인했다.
- LazyVim 플러그인 33개의 커밋이 저장소 lock과 일치한다. Mason 도구 11개와 Tree-sitter 파서 26개 설치·로딩을 확인했다.
- 설치 진입점을 다시 실행해 관리 파일의 내용·링크·권한과 CLI 버전이 동일함을 확인했다. `chezmoi verify`가 통과하고 diff는 비어 있다.
- 실제 KDE Wayland에서 Ghostty의 Zsh 창과 Orca GUI를 확인했다. Orca 첫 설정 화면이 Claude·Codex·Grok·OpenCode·Pi·Antigravity·Aider·Kiro의 8종 CLI를 감지했다. 같은 Claude의 Agent Teams 항목까지 포함해 화면에는 9개가 표시됐다. 기본 agent 선택과 인증은 사용자에게 남겨둔다.
- Wayland 복사·붙여넣기와 Neovim `+` register 읽기를 확인하고 원래 클립보드 내용을 복원했다. 클립보드 원문은 보고서에 저장하지 않았다.
- Orca가 추가한 Claude hooks 13개와 statusLine을 보존했다. 앱이 644로 바꾼 설정 파일 권한만 600으로 복원했으며 내용은 변경하지 않았다.
- 기본 QGA·SELinux·fstab 파일과 custom Boolean이 원래 상태임을 확인했다. Fedora 기존 검토 설정 11개의 내용·권한도 그대로다. Ubuntu·Arch 등 다른 VM은 실행하거나 수정하지 않았다.
- 일회성 사용자 GUI 검증의 autostart 항목을 제거했다. 검증 VM을 정상 종료하고 남은 마운트가 없음을 확인한다.

검증 보고서는 개인 백업의 `verification.json`, `desktop-editor-verification.json`, `desktop-session-verification.json`, `clipboard-verification.json`, `final-verification.json`에 있다. 인증정보나 클립보드 원문은 저장소에 넣지 않는다. 파티션·GRUB·VM 정의·공유 SSD 보호 훅은 변경하지 않았다. 공유 SSD 동시 접근을 막는 기존 훅이 작업용 잔여 마운트를 차단했고, Fedora 재부팅으로 정리한 뒤 GUI 확인을 마쳤다. 이후 오프라인 마무리는 `unshare --mount --propagation private`의 독립 공간에서 수행하고 작업 마운트를 모두 해제했다.

코드 `c84169a`의 [Installation checks](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38154063232)는 Fedora baseline·Ubuntu baseline·Ubuntu full·Arch full·openSUSE full 다섯 job에서 통과했다. 같은 코드의 [Foundation checks](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38154063296)는 Linux·Windows·macOS에서 통과했다. CI 성공은 네이티브 재부팅·GUI·AI 서비스 인증·Windows/macOS 실사용 배포 완료를 뜻하지 않는다.

## 복구

`manifest.json`과 `originals/`를 기준으로 원래 존재했던 파일과 없었던 파일을 구분한다. 적용 후 작성한 사용자 설정·인증·Orca hooks를 확인한 뒤 대상만 복구한다. 로그인 셸만 되돌리려면 openSUSE에서 `chsh -s /bin/bash`를 실행한다. 삭제되지 않은 기존 RPM을 복원할 필요는 없다. 추가 패키지 삭제는 의존성과 이후 사용 여부를 별도로 확인한다. 공유 SSD를 사용하는 다른 Desktop VM과 호스트 마운트를 동시에 켜지 않는다.
