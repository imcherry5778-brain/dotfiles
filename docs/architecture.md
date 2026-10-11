# 설계와 폴더 규칙

조직은 `imcherry5778-brain`, 저장소는 `dotfiles`다. 로컬 위치는 실제 사용자 홈 아래 `projects/imcherry5778-brain/dotfiles`로 구성한다. 조직 상위 폴더와 저장소 안의 home을 Git 루트로 혼동하지 않는다.

## 책임

| 위치/도구 | 책임 |
|---|---|
| home + chezmoi | 개인 설정 파일, 공유 기본값, 기기 차이 |
| home/dot_config/mise | 향후 전역 CLI 버전·잠금·설치 선언 |
| 루트 mise.toml | 저장소 운영 작업. 현재 plan/check만 |
| install.sh / install.ps1 | 최초 진입점. 현재는 읽기 전용 계획·검사 |
| scripts/unix, scripts/windows | 해당 셸 문법의 실제 구현 |
| docs | 정책·절차·확인한 근거 |
| tests | 임시 홈에서 실행하는 검증과 fixture |

`.chezmoiroot`에 `home`을 지정해 docs/scripts/tests가 배포 대상에 섞이지 않도록 한다. 관련 chezmoi 특수 파일은 home 안에 둔다.

OS별로 전체 홈 설정을 복제하지 않는다. 공통 앱 설정은 한 소스로 유지하고 차이가 필요한 파일만 템플릿으로 만든다. 실제 앱 경로를 .config로 강제 통일하지 않는다. Windows의 Documents·AppData·프로필 경로는 해당 기기에서 발견한다.

## 현재 구조와 확장 순서

현재 home에는 기본 데이터·초기화 템플릿과 예약 위치를 설명하는 문서만 있다. 배포 경계 `**`가 모든 사용자 대상을 제외한다. 앱 설정, 외부 다운로드 선언, 실행 훅, 설치 도구 버전은 아직 없다.

1. Fedora의 실제 최신 파일·버전·공급자와 이전 범위를 재확인한다.
2. Zsh·Git·completion·터미널/tmux·Neovim을 작은 변경 단위로 이전한다.
3. 일반 CLI와 AI CLI의 설치 주체·버전을 검증하고 선언한다.
4. Ubuntu·Windows에서 공통 설계를 검증하고 Arch·openSUSE·macOS로 확장한다.
5. 갱신·복구 작업과 실제 기기 검증 기록을 추가한다.

현재 단계에서 모두 빈 config 파일로 만들지 않는다. 예를 들어 기존 기본값만 쓰는 bat·fd·rg·Yazi·lazygit에는 실제 사용자 설정 요구가 생길 때 파일을 추가한다.

## 네이밍

일반 디렉터리는 소문자, 직접 만드는 여러 단어 파일은 하이픈을 쓴다. 앱이 지정한 파일명과 chezmoi 속성은 그대로 사용한다: config.toml, AGENTS.md, CLAUDE.md, dot_zshrc.tmpl, modify_settings.json.tmpl.

common/utils/misc 같은 이름이나 번호별 셸 모듈을 먼저 만들지 않는다. 루트 install.sh/install.ps1과 별도 bootstrap/setup 파일을 중복 유지하지 않는다. 현재 mise 작업은 루트 TOML에서 선언하며 별도의 .mise/tasks 사본을 두지 않는다.

도구의 설치 결과와 사용자 원본을 구분한다. CLI 바이너리, 플러그인 캐시, 외부 프로젝트의 .git, 생성 completion은 저장소에 넣지 않는다. CLI lockfile과 LazyVim의 사용자 lazy-lock.json은 실제 도입 단계에서 관리한다.
