# dotfiles

`imcherry5778-brain/dotfiles`는 Linux·Windows·macOS의 개인 CLI와 설정을 재현하기 위한 저장소다. chezmoi는 설정과 기기 차이를, mise는 CLI 설치와 버전을 관리한다.

**현재 단계: Fedora 설정 초안 구성. 실제 홈 적용·도구 설치는 하지 않았다.** 실제 Fedora에서 선정한 설정과 버전을 source에 구성했다. [유지·변경·제외 판단](docs/fedora-review.md)을 먼저 확인한다.

## 위치와 구조

각 OS의 사용자 홈 아래 `projects/imcherry5778-brain/dotfiles`를 작업 위치로 사용한다. chezmoi의 `sourceDir`는 저장소 루트를 가리키고 `.chezmoiroot`의 `home`이 배포 소스를 지정한다. 기본 chezmoi 위치에 두 번째 checkout이나 연결용 심볼릭 링크를 만들지 않는다.

```text
dotfiles/
├── install.sh / install.ps1   # 현재는 계획 출력·사전 검사만
├── mise.toml                 # 저장소 운영 작업
├── home/                     # chezmoi 소스: 기기 데이터·선택할 설정
│   ├── .chezmoitemplates/    # 재사용 조각
│   └── dot_config/           # 검토한 앱별 설정 원본
├── scripts/unix/             # POSIX 구현
├── scripts/windows/          # PowerShell 구현
├── docs/                     # 설계·설치·관리·지원 범위
├── tests/                    # 격리된 검증·플랫폼 fixture
└── .github/workflows/        # Linux·Windows·macOS 기반 검증
```

`deployment.enabled=false`가 기본값이라 모든 배포 대상이 제외된다. Fedora preview만 임시 홈에서 명시적으로 활성화해 검증한다. 업스트림 다운로드도 별도 비활성 기본값이다. 문서용 README와 빈 설정을 홈으로 배포하지 않는다.

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

mise를 이미 사용하는 기기에서는 저장소 루트에서 `mise run plan` / `mise run check`로 같은 동작을 호출할 수 있다. 이 저장소는 mise를 자동 설치하지 않는다.

검사는 설치 도구의 누락을 알려주지만 설치하지 않는다. 계획 출력은 의존성 설치 없이 사용할 수 있다. 실제 bootstrap, CLI 설치, 업데이트, 설정 적용은 후속 변경이다.

## 상세 문서

- [Fedora 유지·변경·제외 판단](docs/fedora-review.md)
- [설계와 폴더 규칙](docs/architecture.md)
- [최초 설치와 현재 진입점](docs/install.md)
- [설정과 기기 데이터](docs/configuration.md)
- [CLI·프로필 범위](docs/tools.md)
- [AI CLI와 Orca](docs/ai.md)
- [업데이트](docs/update.md), [복구](docs/restore.md)
- [플랫폼별 검증 수준](docs/platforms.md)
- [검증 실행](tests/README.md)
- [공식 근거와 실제 사례](docs/research.md)
