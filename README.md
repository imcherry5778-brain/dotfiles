# dotfiles

`imcherry5778-brain/dotfiles`는 Linux·Windows·macOS의 개인 CLI와 설정을 재현하기 위한 저장소다. chezmoi는 설정과 기기 차이를 관리한다. 공통 CLI는 mise로 관리하고, Windows의 PowerShell·Git·mise·chezmoi는 WinGet으로 준비한다. AI CLI는 도구별 공식 설치 경로를 사용한다.

**현재 단계: 개인 Fedora·Ubuntu·Arch·openSUSE 적용 완료와 GitHub-hosted 설치 검증.** Fedora는 공통 CLI 13개와 기존 개인 도구를, Ubuntu·Arch·openSUSE는 공통 13개·AI CLI 8개·Node, 총 22개를 mise로 관리하고 Ghostty·Orca를 각 OS의 공식 패키지 또는 AppImage로 설치했다. [Fedora 적용 결과](docs/fedora-application.md), [Ubuntu 적용 결과·복구](docs/ubuntu-application.md), [Arch 적용 결과·복구](docs/arch-application.md), [Fedora 유지·변경 판단](docs/fedora-review.md)을 확인한다. 다른 OS의 실제 적용은 별도 단계다.

## 위치와 구조

각 OS의 사용자 홈 아래 `projects/imcherry5778-brain/dotfiles`를 작업 위치로 사용한다. chezmoi의 `sourceDir`는 저장소 루트를 가리키고 `.chezmoiroot`의 `home`이 배포 소스를 지정한다. 기본 chezmoi 위치에 두 번째 checkout이나 연결용 심볼릭 링크를 만들지 않는다.

```text
dotfiles/
├── install.sh / install.ps1   # 기본 계획·검사, 명시적 Fedora/Ubuntu/Arch/openSUSE 설치
├── mise.toml                 # 저장소 운영 작업
├── home/                     # chezmoi 소스: 기기 데이터·선택할 설정
│   ├── .chezmoitemplates/    # 재사용 조각
│   └── dot_config/           # 검토한 앱별 설정 원본
├── scripts/lib/              # OS 판별·검증 다운로드·native 앱 설치 공통 구현
├── scripts/unix/             # POSIX 진입점과 Linux 프로필 구현
├── scripts/windows/          # PowerShell 구현
├── docs/                     # 설계·설치·관리·지원 범위
├── tests/                    # 격리된 검증·플랫폼 fixture
└── .github/workflows/        # 3개 OS 기반 검증 + Fedora/Ubuntu/Arch/openSUSE 실제 설치 검증
```

`deployment.enabled=false`가 기본값이라 모든 배포 대상이 제외된다. 새 기기에서는 명시적인 선택이 필요하다. 개인 Fedora·Ubuntu·Arch·openSUSE에서는 각 OS의 로컬 기기 데이터로 배포를 활성화했다. 업스트림 다운로드도 별도 비활성 기본값이다. 문서용 README와 빈 설정을 홈으로 배포하지 않는다.

## 지금 실행할 수 있는 것

Linux/macOS:

```sh
sh install.sh --plan
sh install.sh --check
```

PowerShell 7:

```powershell
./install.ps1 -Mode Plan
./install.ps1 -Mode Check
```

mise를 이미 사용하는 기기에서는 저장소 루트에서 `mise run plan` / `mise run check`로 같은 동작을 호출할 수 있다. 기본 plan/check는 도구를 설치하지 않는다.

검사는 설치 도구의 누락을 알려주지만 설치하지 않는다. 계획 출력은 의존성 설치 없이 사용할 수 있다. 명시적 `--apply --profile FILE`은 Fedora common baseline과 Ubuntu 26.04·Arch·openSUSE Tumbleweed x86_64 desktop/full profile을 지원한다. GitHub-hosted Ubuntu 러너에서 Fedora 44·Ubuntu 26.04·Arch·openSUSE 컨테이너를 만들고 같은 진입점으로 실제 설치·Zsh/tmux·반복 적용을 검사한다. Ubuntu·Arch·openSUSE 기본 프로필은 15개, full 프로필은 22개 CLI와 Ghostty·Orca를 선택하며 기존 Bash 설정을 보존한다. Self-hosted runner와 사용자 PC는 사용하지 않는다. 개인 Fedora에 baseline profile을 적용하면 안 된다. 자세한 계약은 [설치 문서](docs/install.md)에 있다.

## 상세 문서

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
