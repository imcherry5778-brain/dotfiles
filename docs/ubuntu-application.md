# 개인 Ubuntu 적용 기록

2026-10-11, 사용자가 승인한 Ubuntu 26.04.1의 실제 사용자 홈에 코드 commit `05eb74f`를 적용했다. Fedora 호스트의 `Desktop / Ubuntu · GNOME` VM에서 설치·검증했으며 기존 Ubuntu 파티션을 사용했다. 이 기록은 hosted CI와 별개다. 새 CLI 설정으로 네이티브 부팅을 다시 검증한 단계는 아니다.

## 적용 직전 검토와 백업

최신 소스와 Ubuntu 현황을 다시 비교했다. 일반 설정 대상은 기존 변경 1개(.bashrc), 새 파일 28개였고 .profile/.bash_logout은 보존했다. 외부 플러그인 배포를 포함한 최종 관리 경로는 1,944개다.

복구본은 **Ubuntu 사용자 홈 안**의 `~/.local/state/dotfiles/backups/20261011T130108Z`에 있다. 같은 경로의 Fedora 홈과 구분한다. 원본 세 파일, 원래 권한·해시·로그인 셸, 생성 대상 목록, 적용 전 diff와 프로필을 기록했다. 디렉터리는 700, 백업 파일은 600이다. 전체 홈·인증 정보·디스크 이미지는 복사하지 않았다.

## 실제 변경

- Git·curl·Zsh·tmux·wl-clipboard·build-essential을 APT로 준비했다. bash-completion은 기존 설치를 사용했다. 기존 패키지 제거·전체 시스템 업그레이드는 하지 않았다.
- mise 2026.10.3과 chezmoi 2.73.0은 검증된 SHA-256으로 설치했다. 공통 CLI 13개와 OpenCode 1.18.35·Node 26.11.1을 선택했다. 도구 선언은 mise 설정 한 곳에서 관리한다.
- Zsh/Oh My Zsh, Bash 공통 모듈, tmux, LazyVim, Git/gh 공통 설정과 선택한 AI 선호를 적용했다. 기본 로그인 셸은 `/bin/bash`에서 `/usr/bin/zsh`로 바꿨다. 실제 새 Ptyxis 창에서도 Zsh가 실행됐다.
- .bashrc의 기존 본문에 공통 모듈 로드 한 줄만 추가했다. .profile/.bash_logout, 기존 APT jq와 system Python, .config/.local/.local/share의 700 권한은 보존했다. .bashrc는 644에서 600으로 제한했다.
- Fedora 추가 도구·Conda·Bitwarden 설정은 선택하지 않았다. delta는 설치했지만 Git pager 기능은 끈 상태다. Git identity와 서비스 인증은 새로 설정하거나 다른 OS에서 복사하지 않았다.

Ubuntu checkout은 `~/projects/imcherry5778-brain/dotfiles`이며 chezmoi sourceDir가 이 저장소를 가리킨다. 로컬 프로필은 deployment.enabled/external=true, ai/editor_web=true, personal_fedora/conda/bitwarden_agent/delta=false다. AI 실행 파일 설치는 OpenCode만 포함한다. 나머지 7개 AI CLI·Ghostty·서비스 로그인은 이번 범위에 포함하지 않았다.

## 실행한 검증

- 15개 CLI의 실제 실행·고정 버전·mise 설치 경로를 확인했다.
- 기존 Bash completion 150개를 모두 보존했고, 적용 후에는 새 공급자를 포함해 167개다. alias·history·기존 본문과 .profile/.bash_logout 해시도 확인했다.
- 실제 PTY에서 Zsh 11개 플러그인·PATH·fzf/zoxide를 검사하고 별도 tmux 서버에서 플러그인 바인딩·마우스 설정을 검사했다.
- LazyVim의 설치된 플러그인 33개의 Git commit이 소스 lock과 일치한다. Python·TypeScript·HTML 등을 포함한 Tree-sitter 파서 26개와 Mason 언어 서버·formatter 등 11개를 설치하고 로드를 확인했다. 개별 언어 서버의 모든 기능은 전수 검사하지 않았다.
- 로그인한 Wayland 세션에서 클립보드 복사·붙여넣기를 검사하고 원래 내용을 복원했다. 실제 Ptyxis 새 창의 Zsh/PTY 실행도 확인했다.
- 플러그인 초기화 후에도 chezmoi verify가 통과하고 diff가 비었다. 반복 apply에서 관리 경로의 내용·권한이 안정적이며 checkout에 설정 변경이 없다.
- Fedora는 읽기 전용 verify와 빈 diff를 확인했다. 파티션·GRUB·VM 정의·공유 SSD 훅·다른 OS 설정은 수정하지 않았다. VM 실행 중 Crucial 파티션은 Fedora에 마운트하지 않았다.

검사 로그와 JSON은 Ubuntu의 `~/.local/state/dotfiles/bootstrap/20261011T130108Z`에 비공개로 남겼다. 사용자 로그인 세션과 새 터미널을 사용할 수 있도록 Ubuntu VM은 실행 상태로 유지했다. VM을 종료하기 전까지 공유 SSD를 Fedora에서 마운트하지 않는다.

## 이후 관리와 복구

버전 갱신은 [업데이트 계약](update.md)에 따라 diff를 확인한 뒤 적용한다. GitHub Actions와 셸 시작은 개인 PC를 자동 갱신하지 않는다. 비공개 저장소를 pull하려면 Ubuntu에서 별도로 GitHub 인증을 해야 한다.

복구 도구는 **Ubuntu에서** 먼저 다음 명령으로 계획을 출력한다.

```sh
python3 "$HOME/.local/state/dotfiles/backups/20261011T130108Z/restore.py"
```

해당 계획을 검토한 뒤 `--apply`를 붙이면 백업된 설정과 기록한 신규 대상·권한을 복구한다. APT 패키지와 mise 설치 캐시는 자동 제거하지 않는다. 로그인 셸까지 되돌릴 경우 `chsh -s /bin/bash`를 별도로 실행한다. 복구본은 적용 전 상태이므로 이후 사용자 수정이 있으면 먼저 그 내용을 보존한다.
