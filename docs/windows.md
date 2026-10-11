# Native Windows 구성

Windows 11 x64 / PowerShell 7을 사용한다. 설치 도구는 제품별로 선택하며 WSL을 요구하지 않는다. Fedora·Ubuntu·Arch·openSUSE의 기존 설치 정책과 공통 버전 파일은 변경하지 않는다.

## 설치와 업데이트 소유권

| 항목 | 설치 담당 | 버전·업데이트 정책 |
|---|---|---|
| PowerShell 7, Git for Windows, mise, chezmoi | WinGet bootstrap | Windows catalog에 bootstrap 버전 기록. 기존 실행 파일이 있으면 보존 |
| rg, fd, bat, jq, fzf, zoxide, gh, lazygit, delta, Neovim, Yazi, uv, Carapace | mise aqua | 공통 CLI 버전을 읽고 Windows backend를 명시 |
| OpenCode | mise GitHub release | 기존 공통 AI 버전 유지, major 변경 없음 |
| Aider | mise pypi → uv | 공통 Aider 버전과 Python 3.12 격리 환경. pip도 공식 설치 옵션에 맞춰 추가 |
| Node, Zig | mise | Node는 편집기와 Pi에 필요. Zig는 Tree-sitter C parser 빌드 의존성 |
| agy, Claude, Codex, Pi, Kiro, Grok | 공식 Windows 설치기 | 검토한 설치기 원문 SHA-256 고정. 설치 payload·업데이트는 공급사 정책 |
| Orca | 공식 EXE | 기존 release metadata의 SHA-256 검증. 실제 GUI와 bundled CLI 별도 검증 |
| Ghostty | Windows 제외 | 공식 Windows release가 없음. 기존 Windows Terminal 유지 |

WinGet 설치기도 공식 MSI/EXE를 실행할 수 있고 mise도 공식 release를 받는다. 여기서 provider는 설치·업데이트 책임이며 artifact 출처와 구분한다. 공통 CLI는 mise에만 선언하고 공식 AI 설치 항목은 mise에서 제외한다. Scoop·Chocolatey·별도 pipx는 추가하지 않는다.

`home/.chezmoidata/windows.json`은 bootstrap ID, Windows backend 매핑, 공식 설치기 URL·SHA·인수·업데이트 소유자를 기록한다. CLI 버전은 공통 mise 원본에서 읽는다. `config.windows.toml.tmpl`은 Windows 전용 mise 환경만 생성한다. Linux의 `pipx:aider-chat`는 그대로 보존하며 Windows에서만 `pypi:aider-chat`를 사용한다.

공식 설치기는 다운로드한 로컬 파일을 해시 검증한 뒤 별도 프로세스로 실행한다. 스크립트 내용이 변경되면 실패하며 검토 후 해시를 갱신해야 한다. 이 해시는 검토한 파일과의 동일성 검사이며 공급사 서명 검증이라고 표현하지 않는다. 공급사 payload의 검증 방식은 각각 설치기에 따른다. 설치기의 pin과 설치되는 제품 버전의 pin도 구분한다.

Claude는 stable 인수를 사용한다. Codex는 공식 latest release 선택과 비대화형 옵션을 사용한다. Pi는 공식 managed install로 의존성을 고정하고, 먼저 mise Node와 Git을 준비해 추가 runtime 설치를 피한다. Grok은 보조 payload까지 공급사 설치기가 처리한다. Kiro는 공식 스크립트의 Windows MSI 설치를 사용하며 실제 사용자별 `LocalAppData/Kiro-Cli` 또는 시스템 `Program Files/Kiro-Cli` 위치를 확인한다.

기존 명령이 있으면 자동 제거·공급자 전환·업데이트를 하지 않는다. 반복 Apply는 설정을 수렴시키고 도구를 검증한다. 이것이 기존 바이너리까지 저장소 버전과 일치함을 보장하지는 않는다. 공급사 자동 업데이트를 허용하는 도구에 대해 OS 간 exact version이 영구히 같다고 주장하지 않는다.

## 코드와 경로

- `scripts/windows/install.ps1`: 선택 검증, diff, 개인 백업, 설치 순서, chezmoi 적용.
- `scripts/windows/providers.ps1`: 공식 설치기 실행, 실패 처리, PATH 등록. 셸 시작 시 실행하지 않음.
- `scripts/windows/verify-tools.ps1`: 실제 명령 실행과 기능 검사, 개인 검증 보고서.
- `home/.chezmoitemplates/windows/plan.json.tmpl`: 중복 선언 없이 provider 계획 렌더링.

| 대상 | 위치 |
|---|---|
| 체크아웃 | 실제 사용자 홈의 `projects/imcherry5778-brain/dotfiles` |
| PowerShell 7 loader | `Documents/PowerShell/profile.ps1` |
| PowerShell 설정 | `.config/powershell/Dotfiles.ps1` |
| mise Windows 환경 | `.config/mise/miserc.toml`, `config.windows.toml` |
| Neovim / LazyVim | `AppData/Local/nvim` |
| GitHub CLI 비인증 설정 | `AppData/Roaming/GitHub CLI/config.yml` |
| diff·실행 보고서 | `.local/state/dotfiles/review/windows` |
| 개인 백업·설치 로그 | `.local/state/dotfiles/backups/<timestamp>-windows` |

chezmoi가 설정을 배포하므로 사용자 연결용 symlink나 Developer Mode를 요구하지 않는다. Codex 공식 설치기가 내부적으로 사용하는 junction과 이 설정 배포 방식은 별개다. OneDrive 등으로 Documents/AppData가 변경된 환경은 현재 적용 전에 중단하며 별도 경로 검토가 필요하다.

PowerShell loader는 기존 내용을 보존하며 한 번만 추가된다. PowerShell 5.1 프로필·기본 별칭·Claude/Orca 훅·미관리 AI 설정과 인증은 보존한다. mise/zoxide/Carapace 초기화, PSReadLine history prediction, Tab 완성, Up/Down 기록 검색, fzf Ctrl+R/Ctrl+T, Yazi `yy`를 제공한다. Yazi `file.exe`는 Git for Windows에서 탐색하여 `YAZI_FILE_ONE`으로 지정한다.

## 실행

처음에는 Windows PowerShell에서 PowerShell 7을 준비한다.

```powershell
winget install --id Microsoft.PowerShell --exact --source winget
```

`Get-ExecutionPolicy -List`를 백업한 뒤, 개인 기기의 Restricted 정책에는 `CurrentUser RemoteSigned`를 사용한다. MachinePolicy/UserPolicy가 있으면 우회하지 않는다. 시스템 전체 Bypass/Unrestricted는 설정하지 않는다.

PowerShell 7에서 체크아웃 루트로 이동하여 실행한다.

```powershell
./install.ps1 -Mode Bootstrap
./install.ps1 -Mode Diff
./install.ps1 -Mode Apply
./install.ps1 -Mode Verify
```

Apply는 관리 대상, 공급사가 추가할 수 있는 PowerShell 프로필, Pi/Grok 설정, 사용자 PATH와 실행 정책을 개인 ACL 백업에 기록한다. mise 환경을 먼저 적용·설치한 뒤 공식 AI 설치기를 실행하고 공급사 설정 변경 후 diff도 저장한다. 마지막에 전체 설정을 적용한다.

Orca 설치 UI는 공식 설치기의 표시를 따른다. Windows Terminal의 기존 설정은 덮어쓰지 않는다. 로그인·구독·API 인증은 설치와 분리한다.

## 검증

격리 테스트는 공백 경로와 반복 적용, Windows native 대상, 프로필/훅 보존, Windows 파일명, 공급자 중복, PowerShell 문법을 확인한다. provider adapter 테스트는 해시 불일치 시 미실행과 반복 설치 보존을 확인한다. 실제 Apply/Verify는 명령 버전뿐 아니라 rg/fd 검색, jq 처리, bat 읽기, fzf 선택, Git 초기화, AI help 실행, Neovim runtime, Aider Python 3.12를 검사한다.

편집기 플러그인·GUI·클립보드 검증과 AI 인증 성공 여부는 기기 기록에서 따로 보고한다. 격리 CI 성공을 실제 제품 설치 성공으로 표현하지 않는다.

공식 근거: [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows), [mise](https://mise.jdx.dev/installing-mise.html), [aqua](https://mise.jdx.dev/dev-tools/backends/aqua.html), [Aider](https://aider.chat/docs/install.html), [OpenCode](https://opencode.ai/docs/), [Antigravity](https://www.antigravity.google/docs/cli/install), [Claude](https://code.claude.com/docs/en/setup), [Codex](https://learn.chatgpt.com/docs/codex/cli), [Pi](https://github.com/earendil-works/pi), [Kiro](https://cli.kiro.dev/install.ps1), [Grok](https://x.ai/cli/install.ps1), [Yazi](https://yazi-rs.github.io/docs/installation/), [Orca](https://www.onorca.dev/docs/install), [Ghostty](https://ghostty.org/docs/install/binary).

Windows WinGet에서 제공되는 mise 2026.9.18로 실제 설치를 검증한다. 저장소 작업의 최소 버전도 이에 맞추며 Linux에 설치된 mise 버전이나 기존 설정은 변경하지 않는다.
