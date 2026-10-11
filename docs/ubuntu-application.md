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

Ubuntu checkout은 `~/projects/imcherry5778-brain/dotfiles`이며 chezmoi sourceDir가 이 저장소를 가리킨다. 로컬 프로필은 deployment.enabled=true·deployment.externals=true, ai/editor_web=true, personal_fedora/conda/bitwarden_agent/delta=false다. AI 실행 파일 설치는 OpenCode만 포함한다. 나머지 7개 AI CLI·Ghostty·Orca는 이 초기 적용 단계에는 포함하지 않았다. 아래 후속 적용에서 설치했으며 서비스 로그인은 별도로 남긴다.

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

## AI CLI·Ghostty·Orca 후속 적용

같은 날 추가 설치 코드 `3c6e703`과 bytecode 생성 방지 수정 `bcf482f`를 Ubuntu 실제 홈에 적용했다. 공식 공급자 선정·공통 코드 분리·OS별 지원 범위는 [설치 자동화 근거](installation-automation.md)에 기록했다.

적용 직전 diff는 새 `.config/mise/config.ai-managed.toml`과 기존 `miserc.toml`의 환경 선택 한 줄뿐이었다. 로컬 chezmoi의 managed_ai/desktop 선택을 true로 전환했고 나머지 기기 데이터는 보존했다. Ubuntu 안의 `~/.local/state/dotfiles/backups/20261011T133538Z`에 원본 chezmoi.toml·miserc.toml, 기존 1,433개 경로의 해시·권한/존재 정보, 기존 15개 tool 기록, 최신 diff·프로필·패키지 변경 계획을 저장했다. 디렉터리는 700, 파일은 600이다.

- agy 1.3.3, Claude 2.1.296, Codex 0.162.1, Aider 0.86.2, Pi 1.1.0, Kiro CLI 2.29.1, xAI Grok Build 1.0.50을 mise로 추가했다. 기존 OpenCode 1.18.35와 Node를 포함한 총 22개 도구의 실제 버전 실행·mise 경로를 확인했다. 새 로그인 Zsh에서 AI 8개 실행 파일을 찾는 것도 검증했다.
- Aider는 uv가 제공하는 별도 Python 3.12 환경을 사용했다. system Python 3.14.4는 그대로다. Pi는 공식 npm 패키지의 install scripts 비활성 옵션을 사용했다.
- Ghostty는 Ubuntu 공식 APT `1.3.0~us1-0ubuntu1.1`, Orca는 SHA-256을 확인한 공식 .deb 1.4.224를 설치했다. Orca 의존성으로 xserver-common만 `2:21.1.22-1ubuntu1`에서 `2:21.1.22-1ubuntu1.2`로 갱신했고 기존 패키지는 제거하지 않았다. Ghostty의 --version은 이 Ubuntu 빌드를 `1.3.0-dev+0000000`으로 표시하므로 패키지 버전과 함께 기록했다.
- 기존 15개 도구의 버전·설치 경로와 기존 설정 1,430개 경로의 내용·권한/링크, Bash completion 150개, .profile/.bash_logout, Zsh·tmux 기능을 보존했다. 전체 installer 반복 실행 후 관리 경로와 tool 상태가 같고 chezmoi verify 통과·빈 diff·깨끗한 checkout을 확인했다. 검증 중 남은 Python import cache 세 파일은 제거하고 installer가 source checkout에 bytecode를 만들지 않게 수정했다.
- 로그인된 Wayland 세션에서 Ghostty가 실제 PTY의 Zsh를 실행했다. Orca 공식 CLI로 앱 창 available·runtime reachable/ready·graph ready·appVersion 1.4.224를 확인했다. 첫 실행 환경은 기본값을 유지했다. Ghostty config는 활성 설정이 없어 새 빈 파일을 배포하지 않았다. 최초 검증 프로세스가 종료될 때 함께 닫히는 것을 확인해 실제 사용자 세션의 transient systemd user unit으로 다시 실행했다. 재부팅 자동 시작 설정은 만들지 않았다. VM 화면 캡처에서 Ghostty 창과 Orca 첫 실행 화면을 확인했고, Orca가 AI 8개를 모두 감지했다(Claude Agent Teams 항목까지 감지 목록 9개). 기본 에이전트 선택·프로젝트 설정은 초기 화면에 남겨 사용자가 결정하도록 했다.
- Fedora의 기존 설정 11개에 대한 해시·권한과 chezmoi verify·빈 diff를 확인했다. Fedora에 init/apply를 실행하거나 기존 AI 공급자·Ghostty·Orca를 바꾸지 않았다. Windows/macOS 앱 분기 계약은 CI로 검사했지만 실제 기기에 설치한 단계는 아니다.

Ubuntu 백업 폴더의 `full-verification.json`, `ghostty-verification.json`, `orca-verification.json`, 설치 로그에 결과를 남겼다. 인증·유료 모델 실행은 수행하지 않았으며 다른 OS의 credentials를 복사하지 않았다. Ubuntu VM과 새 앱은 실행 상태로 남겼다. 설치 코드 bcf482f의 [hosted cold-install 검사](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38144167708)도 Fedora 기본·Ubuntu 기본·Ubuntu full 세 작업 모두 통과했다.

이번 추가 선택만 되돌리는 복구 도구는 **Ubuntu 사용자로** 다음과 같이 계획부터 확인한다.

```sh
python3 "$HOME/.local/state/dotfiles/backups/20261011T133538Z/restore.py"
```

`--apply`는 원본 chezmoi.toml·miserc.toml을 복원하고 추가한 config.ai-managed.toml만 삭제한다. 적용 후 사용자가 해당 파일을 수정했다면 중단한다. 설치된 CLI 캐시·APT 앱·앱 실행 데이터는 자동 제거하지 않는다. 초기 전체 설정 복구와 이번 추가 선택 복구는 서로 다른 시점이다.
