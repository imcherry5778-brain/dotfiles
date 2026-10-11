# chezmoi 중심 설치 계약

지원: Fedora 44·Ubuntu 26.04·Arch·openSUSE Tumbleweed x86_64, Windows 11 x64, Apple Silicon Mac. FreeBSD 제외.

## 최초 설치

Git clone은 홈 아래 `projects/imcherry5778-brain/dotfiles`에 한다. private 저장소 읽기 인증과 Git은 clone 전에 준비한다. 관리자 암호·Apple Command Line Tools·앱 권한·서비스 인증은 직접 처리한다.

chezmoi가 준비되어 있으면 저장소 루트에서:

```sh
chezmoi init --apply --source "$PWD"
```

PowerShell에서는 `chezmoi init --apply --source (Get-Location).Path`를 사용한다.
chezmoi가 없으면 같은 초기화로 이어지는 bootstrap:

```sh
sh install.sh --apply
```

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./install.ps1 -Mode Apply
```

Unix bootstrap은 기존 모듈로 mise·고정 설치기 Python·chezmoi를 준비한다. Mac은 Homebrew를 유지한다. Windows 진입점은 PowerShell 5.1에서 7을 준비하고 WinGet bootstrap을 재사용한다. 기존 설치 출처를 자동 이전하거나 전체 업그레이드하지 않는다.

`init`만 실행하면 비활성 검토 설정을 만든다. fresh `init --apply`는 해당 OS `tests/profiles/*-full.json`의 portable full 선택을 저장하고 `automation.enabled=true`로 기록한다. 이전에 초기화된 기기는 프로필과 자동화 선택을 보존한다. 기존 개인 Fedora를 새 full 프로필로 바꾸려 하면 실패한다. 명시적 CLI-only/공통 프로필을 사용하려면 호환 진입점의 `--profile FILE` / `-ProfilePath FILE`을 사용한다. OS 자동 감지와 source-root 계산은 chezmoi 초기화가 담당한다.

## 적용 순서

1. 초기화 템플릿에서 기존 기기 선택과 요청의 충돌을 거부한다. chezmoi의 미관리 설정 키는 병합 보존한다. 실제 홈에서 기존 config를 재초기화하면 덮어쓰기 전에 config만 개인 백업한다.
2. `run_before`는 실제 홈·OS·선택을 검증하고 diff·변경 대상·권한·심볼릭 링크를 기존 백업 모듈로 보관한다. 필수 OS 패키지를 준비한다.
3. chezmoi가 설정과 고정 외부 소스를 적용한다.
4. 일반 `run_after`가 mise의 선택된 도구를 설치하고, 삭제된 실행 파일 때문에 손상된 선택 버전만 복구한다. 선언이 바뀌지 않아도 매 apply에서 누락을 검사한다. AI 공식 설치와 GUI 앱은 기존 모듈을 재사용한다.
5. 실제 CLI 실행과 설정 일치를 검증한다. GUI·서비스 인증은 별도다.

전후 스크립트는 `.chezmoiscripts/`에 있으며 홈에 파일로 배포하지 않는다. 일반 `run_`을 사용하므로 `run_once`/`run_onchange`의 성공 이력 때문에 누락 복구가 건너뛰어지지 않는다.

## 재귀 실행과 공식 설치기의 설정 수정

설치 단계는 부모 chezmoi에 `init`/`apply`/`update`를 다시 호출하지 않는다. 백업 대상과 diff·최종 verify만 동일한 config/source/destination을 사용하는 읽기 전용 chezmoi 명령으로 조회한다. 각 조회 묶음은 별도의 임시 state DB를 사용해 부모 apply의 DB 잠금을 재진입하지 않는다. 부모의 state/cache 설정이나 잠금 기능을 바꾸지 않는다. 실제 부모 apply가 잠금을 보유한 상태에서 이 동작을 격리 테스트로 확인한다.

공식 설치는 설정 적용 후 실행한다. 설치기가 수정할 수 있는 chezmoi 관리 셸 loader는 직전 내용·권한/Windows ACL을 보관했다가 실패 시에도 복원한다. vendor PATH·인증·미관리 설정은 유지한다. Linux portable full의 AI는 기존 native provider가 발견되면 묵시적으로 mise로 이전하지 않는다. Mac·Windows는 기존 native provider를 재사용한다.

## 검토와 백업

```sh
chezmoi diff
chezmoi apply --dry-run --verbose
chezmoi apply
chezmoi verify --exclude=scripts
chezmoi diff --exclude=scripts
```

일반 diff에는 앞으로 실행할 설치 스크립트도 표시된다. 따라서 빈 설정 diff 판단에는 `--exclude=scripts`를 사용한다. diff/dry-run은 설치 단계를 실행하지 않는다. 기존 설치 명령의 기본 Plan/Check도 변경하지 않는다.

개인 설정 백업: `~/.local/state/dotfiles/backups/`. manifest와 RESTORE.md로 변경 파일만 복구한다. Unix는 파일 mode·심볼릭 링크·변경 디렉터리 mode를 기록한다. Windows는 파일 ACL·User PATH·실행 정책을 기록한다. 초기화 전 chezmoi config는 `~/.local/state/dotfiles/init-backups/`의 가장 최근 해당 기록에서 복구한다. 디렉터리 전체나 모든 홈/인증을 수집하지 않는다. 설치된 바이너리의 제거는 설정 복구와 별개다.

## Fedora full과 개인 환경

`fedora-full.json`은 공통 13개·AI 8개·Node, 총 22개와 Ghostty COPR·공식 Orca RPM을 선택한다. 개인 Fedora의 conda·클러스터 도구·Bitwarden·기존 AI provider를 포함하지 않는다. 기존 `fedora-common.json` 및 개인 Fedora 렌더링/소유권의 회귀 검사를 유지한다.

## CI

GitHub-hosted만 사용한다. Foundation은 세 OS의 문법·격리 렌더링·기존 프로필 회귀·다운로드/출처 충돌·백업·loader 실패 복원·실제 chezmoi orchestration/dry-run을 검사한다. Installation은 Fedora common/full, Ubuntu baseline/full, Arch full, openSUSE full, Windows native CLI, Mac ARM64 full을 실제 일회성 환경에 설치한다. 반복 `chezmoi apply`와 선택된 fd 바이너리 삭제 후 복구를 검사한다. 기존 개인 OS에는 적용하지 않는다. Windows Orca는 대화형 공식 설치기이므로 CLI-only hosted 검사에서 제외하고 GUI/auth 결과를 과장하지 않는다.
