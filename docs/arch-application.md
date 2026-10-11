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

실제 적용·검증 결과는 완료 후 아래에 기록한다.
