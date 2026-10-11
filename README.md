# dotfiles

`imcherry5778-brain/dotfiles`는 Linux·Windows·macOS의 개인 CLI와 설정을 재현하기 위한 저장소다. chezmoi는 설정과 기기 차이를 관리한다. 공통 CLI는 mise로 관리하고, Windows의 PowerShell·Git·mise·chezmoi는 WinGet으로 준비한다. AI CLI는 도구별 공식 설치 경로를 사용한다.

**현재 단계: chezmoi 중심 설치 흐름 개편과 hosted CI 검증.** 기존 OS 적용 결과는 다음과 같다. Fedora는 공통 CLI 13개와 기존 개인 도구를, Ubuntu·Arch·openSUSE는 공통 13개·AI CLI 8개·Node, 총 22개를 mise로 관리하고 Ghostty·Orca를 각 OS의 공식 패키지 또는 AppImage로 설치했다. [Fedora 적용 결과](docs/fedora-application.md), [Ubuntu 적용 결과·복구](docs/ubuntu-application.md), [Arch 적용 결과·복구](docs/arch-application.md), [Fedora 유지·변경 판단](docs/fedora-review.md)을 확인한다. Windows 실제 결과는 별도 문서에 기록되어 있다. Mac의 24개 CLI·Ghostty·Orca·셸·편집기·클립보드·재실행 결과와 개인 백업은 [Mac 적용 기록](docs/macos-application.md)에 기록했다.

## 위치와 구조

각 OS의 사용자 홈 아래 `projects/imcherry5778-brain/dotfiles`를 작업 위치로 사용한다. chezmoi의 `sourceDir`는 저장소 루트를 가리키고 `.chezmoiroot`의 `home`이 배포 소스를 지정한다. 기본 chezmoi 위치에 두 번째 checkout이나 연결용 심볼릭 링크를 만들지 않는다.

```text
dotfiles/
├── install.sh / install.ps1   # 최소 bootstrap → chezmoi init --apply
├── mise.toml                 # 읽기 전용 저장소 작업
├── home/                     # chezmoi 소스: 기기 데이터·선택할 설정
│   ├── .chezmoiscripts/     # 설치 전 백업·검사, 설치 후 누락 복구·검증
│   ├── .chezmoitemplates/    # 재사용 조각
│   └── dot_config/           # 검토한 앱별 설정 원본
├── scripts/lib/              # OS 판별·검증 다운로드·native 앱 설치 공통 구현
├── scripts/unix/             # POSIX 진입점과 Linux/Mac 구현
├── scripts/windows/          # PowerShell 구현
├── docs/                     # 설계·설치·관리·지원 범위
├── tests/                    # 격리된 검증·플랫폼 fixture
└── .github/workflows/        # 3개 OS 기반 검증 + Linux/Windows/Mac 설치 검증
```

`chezmoi init`만 실행하면 배포가 비활성인 검토용 설정을 만든다. 새 기기의 `chezmoi init --apply`는 해당 OS의 portable full 프로필과 설치 자동화를 선택한다. 이미 배포가 활성화된 기기의 선택과 자동화 상태는 유지한다. 비활성 검토 설정에서 명시적으로 `init --apply`를 실행하면 full 설치로 전환한다. 개인 Fedora·Ubuntu·Arch·openSUSE에서는 각 OS의 로컬 기기 데이터로 배포를 활성화했다. 업스트림 다운로드도 별도 비활성 기본값이다. 문서용 README와 빈 설정을 홈으로 배포하지 않는다.

## 지금 실행할 수 있는 것

Linux/macOS:

```sh
sh install.sh --plan
sh install.sh --check
```

PowerShell 5.1 또는 7:

```powershell
./install.ps1 -Mode Plan
./install.ps1 -Mode Check
```

mise를 이미 사용하는 기기에서는 저장소 루트에서 `mise run plan` / `mise run check`로 같은 동작을 호출할 수 있다. 기본 plan/check는 도구를 설치하지 않는다.

기본 plan/check는 설치하지 않는다. 지원 OS에서 명시적 적용 명령 하나가 필수 패키지·mise Python·diff·개인 백업·CLI/앱·설정·검증을 이어 실행한다. 프로필별 명령과 관리자/인증 전제는 [설치 계약](docs/install.md)을 따른다. Fedora common과 portable full을 별도로 검사하며, full은 AI 8개·Node·Ghostty·Orca를 포함한다. 기존 개인 Fedora의 34개 도구 선택과 설치 출처를 대체하지 않는다.

Self-hosted runner는 사용하지 않는다. CI는 임시 GitHub-hosted 환경에 설치하며 사용자 PC로 설정을 배포하지 않는다. 서비스 로그인·GUI 권한·실제 데스크톱 검증은 별도다.

chezmoi가 이미 있으면 clone한 저장소에서 다음 명령을 실행한다. chezmoi가 없으면 Linux/Mac은 `sh install.sh --apply`, Windows는 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./install.ps1 -Mode Apply`로 bootstrap과 같은 초기화를 이어 실행한다.

```sh
chezmoi init --apply --source "$PWD"
# 이후 설정 반영과 삭제된 선택 도구 복구
chezmoi apply
# 설치 스크립트를 제외한 순수 설정 차이
chezmoi diff --exclude=scripts
```

개편의 실행 순서·백업·충돌 방지·검증 범위는 [설치 계약](docs/install.md)을 따른다. 이번 개편은 실제 개인 OS에 적용하지 않고 hosted CI에서 검증한다.

## 상세 문서

- [Mac 적용·검증·복구](docs/macos-application.md)
- [Windows 실제 적용 결과·복구](docs/windows-application.md)
- [Native Windows 설치·설정 계약](docs/windows.md)
- [openSUSE 실제 적용 결과·복구](docs/opensuse-application.md)
- [Arch 실제 적용 결과·복구](docs/arch-application.md)
- [Ubuntu 실제 적용 결과·복구](docs/ubuntu-application.md)
- [Ubuntu 구성·적용 전 검토](docs/ubuntu-review.md)
- [Fedora 실제 적용 결과](docs/fedora-application.md)
- [Fedora 유지·변경·제외 판단](docs/fedora-review.md)
- [설계와 폴더 규칙](docs/architecture.md)
- [최초 설치와 현재 진입점](docs/install.md)
- [설정과 기기 데이터](docs/configuration.md)
- [CLI·프로필 범위](docs/tools.md)
- [AI CLI와 Orca](docs/ai.md)
- [AI·Ghostty·Orca 설치 자동화](docs/installation-automation.md)
- [업데이트](docs/update.md), [복구](docs/restore.md)
- [플랫폼별 검증 수준](docs/platforms.md)
- [검증 실행](tests/README.md)
- [공식 근거와 실제 사례](docs/research.md)
