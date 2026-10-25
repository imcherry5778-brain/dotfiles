# Windows 11 적용 기록

2026-10-12에 실제 `Desktop / Windows 11` VM의 `imcherry` 사용자에게 네이티브 Windows 구성을 적용했다. WSL과 추가 패키지 관리자는 사용하지 않았다. Fedora·Ubuntu·Arch·openSUSE의 실제 설정과 VM 정의, 디스크 및 부팅 설정은 변경하지 않았다.

## 설치 구성

- WinGet: PowerShell 7.6.6, Git for Windows 2.55.0, mise 2026.9.18, chezmoi 2.73.0.
- mise: 총 16개: 공통 CLI 13개, Aider 0.86.2, OpenCode 1.19.0, Node 26.11.1. Aider는 uv가 제공하는 Python 3.12.15 격리 환경과 pip를 사용한다.
- 공식 설치기: agy 1.3.3, Claude stable 2.1.287, Codex 0.162.1, Pi 1.1.0, Kiro 2.29.1, Grok 1.0.50. 공급사의 업데이트 정책은 유지한다.
- WinLibs GCC 16.1.0 (`16.1.0-14.0.0-r4`): Windows Tree-sitter 파서용 C 컴파일러를 WinGet으로 설치했다. Linux 컴파일러와 공통 Neovim 옵션은 유지한다.
- Orca 1.4.224: SHA-256을 확인한 공식 Windows EXE. Ghostty는 공식 Windows 빌드가 없어서 기존 Windows Terminal을 유지한다.

OpenCode 1.19.0은 작업 시작 전에 이미 존재했던 로컬 `config.ai.toml` 변경을 따른 값이다. 그 공통 파일은 이 작업에서 수정하거나 커밋하지 않았다. 저장소에 커밋된 공통 버전은 1.18.35이며, 새 체크아웃에는 그 버전이 적용된다.

mise 설치·검증·공식 설치기 프로세스는 실제 사용자 홈에서 실행해 프로젝트별 mise 선택이 개인 전체 설치에 섞이지 않게 한다. PowerShell이나 `mise run`이 선택한 `MISE_ENV=windows`는 허용하되 다른 환경은 거부한다. 저장소 작업은 실제 검증한 mise 2026.9.18부터 실행할 수 있다.

Pi는 bin 경로를 먼저 등록해 공식 설치기의 마지막 PATH 질문을 피한다. Kiro는 설치기가 출력하는 고정 Program Files 안내 대신 실제 LocalAppData 또는 시스템 설치 위치를 확인한다. 공급사 설치기는 별도 프로세스에서 실행하고, 원문 체크섬이 달라지거나 종료 코드가 실패하면 적용을 중단한다.

## 2026-10-26 공식 설치기 체크섬 검토

Fedora 패키지 이전의 hosted CI에서 기존 Codex 설치기 체크섬 불일치가 발견됐다. [OpenAI 배포 문서](https://learn.chatgpt.com/docs/enterprise/windows-deployment)가 안내하는 `https://chatgpt.com/codex/install.ps1`을 다시 받아 이전 검토본과 비교했다. 실행 코드 변경은 junction 지원 타입 V3, daemon 선택의 USN 식별 및 선택 이력 기록이며 서명 블록도 갱신됐다. 일반 CLI 설치의 공급사·인자·경로는 유지했다.

검토한 원문 SHA-256은 `a59cb66350098c33b021ff470d586ae8fe3b7caf189ca7137b4fe3af5d4dce74`다. `windows.json`의 검토값만 갱신했고 다운로드 검증과 불일치 시 중단 동작은 유지했다. 변경 파일과 이전 원문은 Fedora의 비공개 sys-update 복구 자료에 보관했다. 실제 개인 Windows에는 적용하지 않았으며 실행 검증은 GitHub의 폐기 가능한 Windows runner에서 수행한다. 공급사가 같은 URL을 다시 변경하면 다음 검토가 필요하다.

다음 CI에서 Codex 설치가 통과한 뒤 Pi의 원문 변경도 발견돼 여섯 공식 설치기를 모두 비교했다. Pi만 추가 변경됐으며 agy·Claude·Kiro·Grok은 기존 SHA-256과 같았다. Pi는 UTF-8 BOM이 있는 소유권 표식 처리, 독립 Node 선택 유지, launcher 재작성 및 Node 누락 오류 처리를 보완했다. 검토한 `https://pi.dev/install.ps1`의 SHA-256은 `fd418a3bc57022b8ac1b823f8e42bf2f58b832482ee5e04739b4b4f783767228`이며 이 값만 추가 갱신했다. 공식 Windows 설치 경로는 [Pi 배포 안내](https://pi.dev/)에서 확인했다.

## 백업과 복구 자료

개인 ACL로 제한한 `.local/state/dotfiles/backups` 아래에 관리 대상 파일, 기존 PowerShell 7/5.1 프로필, Pi/Grok 설정, 사용자 PATH, 실행 정책, diff와 설치 로그를 보관했다. 인증 파일을 저장소에 복사하지 않았다.

| 백업 | 내용 |
|---|---|
| `20261011T173904Z-windows-rebootstrap` | WinGet 재준비 전 PATH와 실행 정책 |
| `20261011T175346Z-windows` | 첫 실제 적용 전 관리 대상 및 공식 설치 로그 |
| `20261011T180748Z-windows` | Pi 설치 후 재개 전 상태 및 Kiro 설치 로그 |
| `20261011T181217Z-windows` | Kiro 설치 후 적용 전 상태 및 Grok 설치 로그 |
| `20261011T183210Z-windows` | 편집기 변경 전 상태; 덮어쓰기 대기로 중단한 적용 |
| `20261011T183532Z-windows` | 비대화형 적용 전 상태 |
| `20261011T183928Z-windows` | GCC를 사용한 최종 적용 전 상태 |

Windows 전체 경로는 `C:\Users\imcherry\.local\state\dotfiles\backups\<백업 이름>`이다. PowerShell 실행 정책은 `CurrentUser RemoteSigned`이며 시스템 정책과 그룹 정책은 변경하지 않았다.

## 검증

- CLI 30개: 실제 버전 실행과 rg/fd 파일 검색, jq 처리, bat 읽기, fzf 선택, Git 초기화, AI 8개 help, Neovim runtime, Aider의 Python 3.12 격리 검사. 최종 GCC 포함 30개 모두 통과했다. Orca CLI version/help는 별도로 통과했다.
- LazyVim: 고정된 플러그인 Git checkout을 검증하고 기본 Tree-sitter 파서 29개를 모두 빌드·로드했다. JSON 파싱과 Mason의 Tree-sitter CLI·Prettier 설치 완료를 확인했다. `CC=gcc`는 Neovim 내부 선택이며 사용자 전역 CC를 추가하지 않았다. 검사 오류 0개. 사용하지 않는 임시 Zig 0.15.2는 제거했다.
- PowerShell 7.6.6 실제 Windows Terminal: 프로필 오류 0개, CLI 21개 인식, mise/zoxide/Carapace, `yy`, `EDITOR=nvim`, Git `file.exe` 연동, Tab/Up/Down/Ctrl+R/Ctrl+T 키 바인딩.
- Windows 내부 텍스트 클립보드 round-trip: 기존 텍스트를 복원했다. Fedora↔Windows 공유 클립보드 검증은 아니다.
- Orca: 실제 GUI 첫 실행과 공식 번들 CLI의 version/help. 온보딩의 기본 에이전트 선택과 각 AI 계정 인증은 사용자 설정으로 남겼다.
- Fedora 주요 설정 7개: 적용 전후 해시 동일. 다른 실제 OS의 파일, libvirt 정의, 디스크·부팅 항목은 작업하지 않았다.
 AI 로그인·구독·API 호출 성공과 Windows 네이티브 재부팅은 이번 설치 검증 범위에 포함하지 않는다.

## 임시 검증 연결과 보안 기록

로그인 세션의 임시 작업 연결로 네이티브 PowerShell 검사를 실행했다. 별도의 일회성 원격 진단 실행 명령을 Defender가 `SuspClickFix.G3`와 `AmsiSuspClickfix.B`로 탐지했다. 기록의 대상은 해당 PowerShell 진단 프로세스/AMSI이며 공급사 설치 파일 경로는 없었다. 03:42 KST 재확인에서 두 항목 모두 `IsActive=false`, 조치 성공이었다. 차단을 우회하거나 Defender 예외를 추가하지 않았다. 해당 진단 방식은 중단했고, 임시 서버·작업 연결·방화벽 허용은 완료 시 제거하며, 영구 원격 서비스는 설치하지 않는다.

최종 실제 실행 후 `chezmoi verify`와 비어 있는 diff를 확인했다. Orca desktop setup을 반복 실행해 사용자 PATH가 정확히 동일한 것도 확인했다. 개인 검증 보고서는 `.local/state/dotfiles/review/windows`의 `tool-verification.json`, `editor-verification.json`, `desktop-verification.json`에 남겼다.

GitHub-hosted CI: 기본 Windows/Linux/macOS 검사 [38164921697](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38164921697)와 Fedora·Ubuntu·Arch·openSUSE의 설치 검사 [38164921705](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38164921705)가 모두 통과했다. 실제 Windows 설치는 CI runner가 아닌 개인 VM에서 따로 검증했다.
