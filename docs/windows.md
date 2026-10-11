# Native Windows 구성

Windows 11 x64에서 PowerShell 7과 WinGet을 우선한다. WSL, Zsh, Oh My Zsh, tmux는 Windows 프로필에 배포하지 않는다. 기존 PowerShell 5.1 프로필·기존 명령 별칭·인증 파일은 유지한다.

## 공급자와 버전

`home/.chezmoidata/windows.json`은 WinGet ID, Windows 등록 버전의 예외, bootstrap과 편집기 빌드 의존성을 소유한다. `home/.chezmoitemplates/windows/plan.json.tmpl`은 공통 Linux 도구 선언에서 버전을 읽고 Windows 예외만 덮어써 설치 계획을 만든다. WinGet 도구를 Windows mise 목록에 중복 선언하지 않는다.

- WinGet: 공통 CLI 13개, agy·Claude·Codex·OpenCode·Node = 18개.
- mise: Pi의 공식 npm 패키지, Aider의 uv 기반 Python 3.12 격리 환경, Grok의 공식 Windows 바이너리 = 3개.
- Kiro: 공식 Windows MSI. 버전은 공통 AI 선언을 읽고 고정 MSI 메타데이터와 일치를 검사한다.
- Orca: 기존 공통 release 메타데이터의 공식 Windows 설치 파일과 SHA-256을 재사용한다.
- Ghostty: 공식 Windows 배포판이 없어 설치 대상에서 제외한다. 기존 Windows Terminal을 사용한다.
- Git·PowerShell·mise·chezmoi는 WinGet bootstrap, Zig는 Tree-sitter C parser의 Windows 빌드 의존성이다.

설치 시 이미 명령이 있으면 기존 공급자를 유지한다. 이 보존 동작은 기존 바이너리가 저장소 버전과 같다는 의미가 아니다. 업데이트는 별도로 검토한다. WinGet 등록 지연으로 Linux와 다른 버전은 catalog의 `versions`에 명시한다. Grok SHA는 공식 HTTPS 배포 파일에서 계산한 고정값이며 게시자 서명 검증으로 표현하지 않는다.

## 경로와 설정

각 사용자 홈의 `projects/imcherry5778-brain/dotfiles`가 checkout이다. chezmoi가 실제 설정 파일을 배포하므로 연결용 symlink나 Windows Developer Mode는 필요하지 않다.

| 대상 | 배포 위치 |
|---|---|
| PowerShell 7 loader | `Documents/PowerShell/profile.ps1` |
| 공통 PowerShell 동작 | `.config/powershell/Dotfiles.ps1` |
| mise의 Windows fallback 선택 | `.config/mise/miserc.toml`, `config.windows.toml` |
| Neovim / LazyVim | `AppData/Local/nvim` |
| GitHub CLI의 비인증 설정 | `AppData/Roaming/GitHub CLI/config.yml` |
| Git / AI 공통 설정 | `.config/git`, `.gitconfig`, `.claude/settings.json`, `.codex/config.toml`, `.config/opencode` |

PowerShell loader는 modify 템플릿으로 기존 내용을 보존하며 한 번만 추가된다. `modify_profile.ps1.ps1`의 마지막 `.ps1`은 chezmoi의 modify 스크립트 확장자로 제거되고 대상은 `profile.ps1`이다. Neovim 파일은 공통 Linux 원본을 include하므로 설정 내용을 두 군데에서 관리하지 않는다. OneDrive 등으로 Documents/AppData가 다른 위치에 연결된 기기는 현재 설치기가 적용 전에 중단한다. 이 제한을 무시해 다른 폴더에 프로필을 쓰지 않는다.

PowerShell은 공식 mise·zoxide·carapace 초기화와 PSReadLine history prediction, Tab 메뉴 완성, Up/Down 기록 검색, Ctrl+R fzf 기록 검색, Ctrl+T 파일 선택, `yy` 종료 후 yazi 디렉터리 이동을 제공한다. `ls`·`cat`·`cd` 기본 별칭은 교체하지 않는다. 셸 시작 시 다운로드·설치·AI 에이전트 시작은 하지 않는다.

## 실행 순서

기본 Windows PowerShell에서 먼저 실행한다.

```powershell
winget install --id Microsoft.PowerShell --exact --source winget
```

PowerShell 7의 새 창에서 checkout 루트로 이동한다. 실행 정책이 Restricted인 새 기기에서는 먼저 `Get-ExecutionPolicy -List` 결과를 개인 백업에 기록하고 `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`를 검토해 실행한다. 조직 정책이 있으면 중단한다. 이 단계가 완료돼야 로컬 `.ps1` 진입점을 실행할 수 있다.

```powershell
./install.ps1 -Mode Bootstrap
./install.ps1 -Mode Diff
./install.ps1 -Mode Apply
./install.ps1 -Mode Verify
```

`Restricted`이면 리뷰한 로컬 PowerShell 파일 실행에 `CurrentUser RemoteSigned`가 필요하다. 실행 정책을 변경하기 전 현재 값을 기록하고, MachinePolicy/UserPolicy가 설정돼 있으면 자동으로 우회하지 않는다. 시스템 전체 `Bypass`나 `Unrestricted`는 사용하지 않는다. bootstrap은 PowerShell 7·Git·mise·chezmoi를 설치하며 개인 설정을 배포하지 않는다. Apply는 먼저 관리 대상 설정과 사용자 PATH·정책 값을 사용자 전용 ACL의 `.local/state/dotfiles/backups/<timestamp>-windows`에 보관한다.

## 검증 수준

`tests/verify-windows.ps1`은 실제 Windows에서 공백 경로의 임시 사용자 홈에 적용한다. PowerShell 5.1·사용자 프로필 내용·Claude/Orca 훅·미관리 키 보존, native AppData 경로, provider 중복, Windows 파일명, 두 번째 적용 후 바이트 안정성, 렌더링된 PowerShell 문법을 검사한다. GitHub-hosted Windows 러너에서도 같은 검증을 한다. 이 격리 검증은 도구 다운로드·실제 GUI·AI 인증 성공을 의미하지 않는다. 실제 적용 결과는 별도 기기 기록에 남긴다.

공식 근거: [PowerShell Windows 설치](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows), [WinGet install](https://learn.microsoft.com/en-us/windows/package-manager/winget/install), [Kiro 설치](https://kiro.dev/docs/getting-started/installation/), [Ghostty 기능](https://ghostty.org/docs/features), [Orca 설치](https://www.onorca.dev/docs/install), [mise Windows 경로](https://mise.jdx.dev/directories.html).
