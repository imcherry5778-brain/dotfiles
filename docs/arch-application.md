# Arch KDE 적용

## 공급자와 공통 설정

- 공통 13 CLI + OpenCode + 기존 7 AI CLI + Node: Ubuntu와 같은 mise 버전 목록을 재사용한다. AI 인증과 세션은 복사하지 않는다.
- Bash: Arch 원문과 `.bash_profile`을 유지하고 공통 모듈을 한 번만 불러온다. Zsh/Oh My Zsh, tmux, LazyVim은 공통 원본을 쓴다. KDE·fcitx5 설정은 대상에서 제외한다.
- Node 선언은 `.chezmoitemplates/tools/editor-node.toml.tmpl` 한 곳에 있다. Ubuntu는 이미 적용된 `editor-ubuntu` 이름을 유지하고 Arch만 `editor-web`을 선택한다. 두 파일을 동시에 배포하지 않는다.
- Ghostty: [공식 문서의 Arch extra 패키지](https://ghostty.org/docs/install/binary). GUI 기본값을 사용하며 빈 설정 파일을 만들지 않는다.
- Orca: [공식 Linux AppImage](https://www.onorca.dev/docs/install) 1.4.224, SHA-256 검증 후 사용자 경로에 풀어 배치한다. AppImage 런타임의 `--appimage-extract`로 FUSE 없이 실행하고, 원본 AppRun 및 같은 번들의 CLI를 사용한다. AUR·비공식 재패키징·별도 npm CLI를 사용하지 않는다. `~/.local/bin/orca-ide`는 공식 번들의 CLI를 가리키고 KDE 메뉴에 Orca 실행 항목을 추가한다. 이 풀린 설치의 갱신은 새 공식 릴리스 검토 후 별도로 수행한다.
- Arch의 패키지 DB는 독립 갱신하지 않는다. 기존 DB의 `pacman -S --needed`로 추가 패키지만 설치한다. 오래된 DB로 실패하면 중단하고 전체 시스템 갱신을 별도 검토한다. CI의 새 Arch 컨테이너만 `pacman -Syu`로 준비한다.

## 적용 전 확인

기존 사용자 셸은 Bash이며 `.bashrc`에는 컬러 ls/grep 별칭과 PS1이 있다. chezmoi·mise·Neovim·AI 설정은 없고 시스템 ripgrep/Vim은 존재한다. 시스템 패키지는 제거하지 않는다.

실제 Arch 개인 백업: `~/.local/state/dotfiles/backups/20261011T140221Z`. 원본 Bash 파일, 원래 없던 대상 목록, 설치 전 패키지, KDE·입력기 설정 해시와 기존 로그인 셸을 기록했다. 디렉터리 700, 파일 600이며 저장소에는 개인 백업을 넣지 않는다.

## 실제 적용 결과 — 2026-10-11

기존 Arch 물리 파티션을 사용하는 `Desktop / Arch · KDE` VM의 실제 사용자 홈에 적용했다. CLI 22개의 고정 버전·mise 경로·실행을 확인했고, 공통 CLI 13개와 AI CLI 8개, Node로 구성된다. Ghostty는 1.3.1-2 패키지(실행 버전 1.3.1-arch2), Orca는 1.4.224다.

기존 시스템 패키지 801개의 이름·버전을 모두 유지했다. 원본 `.bashrc`를 보존하고 공통 모듈만 한 번 추가했으며 `.bash_profile`과 KDE·fcitx5 등 기존 설정 9개의 해시가 일치한다. Fedora의 검토 대상 11개 설정 해시·권한도 유지했고 Ubuntu VM은 종료 상태로 보존했다. 파티션·부트로더·VM 정의·SSD 보호 훅은 바꾸지 않았다.

설치 진입점은 로그인 셸을 유지한다. 실제 기기 마무리 단계에서 `/etc/shells`를 확인하고 `imcherry`만 `/bin/bash`에서 `/usr/bin/zsh`로 전환했다. 다음 로그인부터 기본 셸에 반영되며 기존 Bash 파일은 그대로 사용할 수 있다.

## 실제 검증과 경계

- Zsh 실제 PTY의 Oh My Zsh·11개 플러그인과 tmux 실행을 확인했다. Bash 기존 별칭·history 정책·100개 이상의 native completion을 보존했다.
- LazyVim 33개 플러그인이 저장소 lock의 커밋과 일치한다. Tree-sitter 파서 26개와 Mason 패키지 11개를 설치하고 실제 로딩을 확인했다. 첫 시작에 최신 커밋으로 설치된 부분은 lock 버전으로 복원했다.
- KDE Wayland에서 Ghostty의 Zsh 창과 Orca GUI를 확인했다. Orca의 첫 설정 화면에서 Claude·Codex·Grok·OpenCode·Pi·Antigravity·Aider·Kiro가 감지됐다. 기본 agent 선택과 인증은 사용자에게 남겨둔다.
- Wayland 복사·붙여넣기와 Neovim `+` register의 읽기를 확인하고 기존 클립보드 내용을 복원했다.
- Orca가 추가한 Claude hooks와 statusLine을 보존했다. 앱이 바꾼 설정 파일 권한만 600으로 복원해 chezmoi 계약과 일치시켰다.
- 같은 설치 진입점을 다시 실행했을 때 관리 대상의 내용·링크·권한과 설치 버전이 같았고 `chezmoi verify`가 통과하며 최종 diff는 비어 있다.

CLI·editor·desktop 최종 보고서는 개인 백업 안의 `verification.json`, `desktop-editor-verification.json`, `clipboard-verification.json`, `final-verification.json`에 있다. 인증정보나 클립보드 원문은 보고서·저장소에 넣지 않았다. 정상 백업은 유지한다.

코드 commit `56191e3`의 [Installation checks](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38146047528)는 Fedora baseline·Ubuntu baseline·Ubuntu full·Arch full 네 job에서 통과했다. 같은 코드의 [Foundation checks](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38146047509)는 Linux·Windows·macOS에서 통과했다. 실제 GUI 검증은 이 Arch VM에서 별도로 수행했고 네이티브 재부팅·AI 서비스 인증·Windows/macOS 설치 완료를 뜻하지 않는다.

## 복구

변경 전에 기록한 `manifest.json`과 `originals/`를 기준으로 복원한다. 원래 없던 파일을 모두 지우기 전에 이후 사용자가 만든 설정과 Orca의 추가 hooks를 확인한다. 설치 후 작성된 설정·인증은 원본 백업에 없다. 로그인 셸만 되돌리려면 Arch에서 `chsh -s /bin/bash`를 실행한다. 공유 SSD에 접근하는 동안 다른 Desktop VM이나 호스트 마운트를 동시에 사용하지 않는다.
