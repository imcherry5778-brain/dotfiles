# AI CLI와 데스크톱 설치 자동화

2026-10-11에 공식 문서·현재 Fedora 설치·격리된 실제 다운로드를 확인했다. 로그인, 모델 사용 성공, 다른 OS 실사용 배포는 설치 성공과 구분한다.

## 코드 구조와 소유권

- `scripts/unix/install.py`: chezmoi 전후 단계의 프로필 검증·백업·mise 설치·실행 검증. 기본 계획과 설치 동작을 분리한다.
- `scripts/lib/runtime.py`: OS/CPU 판별, 셸을 거치지 않는 명령 실행, 스트리밍 다운로드와 SHA-256 검증, 필요한 패키지 명령의 권한 처리. Linux/macOS/Windows에서 재사용한다.
- `scripts/lib/desktop.py`: OS별 Ghostty·Orca 설치만 담당한다. 기존 설치는 공급자·버전·설정을 유지하며 업그레이드하지 않는다. 설정·인증은 다루지 않는다.
- `scripts/desktop-release.json`: Orca 공식 릴리스 자산과 검증할 SHA-256의 단일 소유자다. Ubuntu/Fedora 패키지와 Arch/openSUSE 공용 AppImage는 1.4.224로 고정한다. macOS는 공식 Homebrew cask, Windows는 공식 설치 프로그램을 사용한다.
- `home/dot_config/mise/config.ai-managed.toml`: 추가 AI CLI 7개의 버전·공급자 단일 소유자다. 기존 shared OpenCode는 `config.ai.toml`에 그대로 둔다. CLI 버전을 별도 설치 목록에 중복 선언하지 않는다.

새 `managed_ai`·`desktop` 선택은 기본 false다. Linux portable full profile에서 켠다. Fedora full은 기존 개인 Fedora와 별도 선택이다. Fedora 기존 도구 선택·vendor/uv 설치·셸·AI config·Ghostty/Orca를 이번 작업으로 이전하거나 업그레이드하지 않는다. 이 표의 AI mise archive는 Linux용이다. Windows는 native provider 계약을, Mac은 Mac 전용 mise/Homebrew/공식 설치기 계약을 따른다. 서로의 provider를 일괄 배포하지 않는다. [최초 설치 계약](install.md)과 [Windows](windows.md)를 확인한다.

## 공식 공급자 판단

| 도구 | 자동화 공급자 | 설치 방식 근거 |
|---|---|---|
| agy | mise aqua 공식 native release, 1.3.3 | [Google 설치 안내](https://www.agy.dev/docs/getting-started), [공식 배포 저장소](https://github.com/google-antigravity/antigravity-cli) |
| Claude | mise aqua 공식 native archive, 2.1.296 | [공식 native 설치·검증](https://code.claude.com/docs/en/setup); npm 방식으로 바꾸지 않는다 |
| Codex | mise aqua OpenAI native release, 0.162.1 | [OpenAI CLI 문서](https://learn.chatgpt.com/docs/codex/cli), [공식 release](https://github.com/openai/codex/releases) |
| Aider | mise pipx backend의 uv 설치, 0.86.2 | [공식 설치](https://aider.chat/docs/install.html); 별도 Python 3.12 환경을 사용하고 system Python은 교체하지 않는다 |
| Pi | mise npm 공식 @earendil-works/pi-coding-agent, 1.1.0 | [Pi 공식 설치](https://pi.dev/); install scripts 비활성 옵션을 유지한다 |
| Kiro | mise HTTP 공식 headless archive, 2.29.1 | [공식 설치 안내](https://kiro.dev/docs/getting-started/installation/), [공식 checksum manifest](https://prod.download.cli.kiro.dev/stable/latest/manifest.json); setup·로그인은 실행하지 않는다 |
| Grok | mise registry의 xAI 공식 native artifact, 1.0.50 | [xAI CLI](https://x.ai/cli), [공식 CLI 참조](https://docs.x.ai/build/cli/reference); 다른 npm Grok 프로젝트와 구분한다 |
| Ghostty | Ubuntu 공식 APT / Arch extra / openSUSE OSS / Fedora COPR / macOS Homebrew | [공식 패키지 안내](https://ghostty.org/docs/install/binary); native Windows 배포는 지원하지 않는다 |
| Orca | Stably 공식 desktop 배포 | [공식 설치](https://www.onorca.dev/docs/install); Linux CLI는 orca-ide로 GNOME 스크린리더와 구분한다 |

mise는 배포물 다운로드·CLI 설치 경로·버전을 관리하고 chezmoi는 위 선택과 설정을 배포한다. [mise HTTP backend](https://mise.jdx.dev/dev-tools/backends/http.html)와 [uv/PyPI backend](https://mise.jdx.dev/dev-tools/backends/pypi.html)의 기능을 사용한다. 설치 자동화를 선택한 기기의 일반 chezmoi 전후 스크립트에서 패키지·CLI·앱을 준비한다. 셸 시작에는 설치나 sudo를 넣지 않는다. 비활성 검토 설정과 기존 자동화 비활성 기기는 설치하지 않는다. 설치된 버전과 공급업체의 자체 업데이트 정책은 별개이며 자동 로그인이나 업데이트 정책 변경은 하지 않는다.

## 명시적 실행

검토한 지원 OS의 새 기기에서는 chezmoi 중심 진입점을 쓴다. 기존 기기에서 profile이 다르면 자동 대체하지 않고 중단하므로 먼저 최신 diff·대상 백업·기기 선택 변경을 검토한다.

```sh
sh install.sh --desktop-plan
chezmoi init --apply --source "$PWD"
# chezmoi가 아직 없으면: sh install.sh --apply
```

GUI 앱에는 OS 패키지 관리자 권한이 필요하다. 사용자 설정·mise 설치는 일반 사용자로 실행한다. 운영자가 시스템 패키지와 사용자 단계를 나눠 실행하려면 `sh install.sh --desktop-only`를 별도로 사용한다. 이 명령은 홈 설정을 배포하지 않는다. Ubuntu에서는 Ghostty 공식 패키지와 공식 Orca .deb만 설치하며 apt의 --no-remove로 기존 패키지 제거를 막는다.

Windows의 `./install.ps1 -Mode DesktopPlan` / `DesktopApply`는 native PowerShell 구현을 사용하며 Python이나 WSL이 필요하지 않다. Linux/Mac 전체 설치기의 Python은 mise가 준비한다. Windows Orca는 미검증 silent flag를 넣지 않아 공식 installer의 사용자 UI가 남는다. Windows Ghostty는 지원 불가를 명시하고 다른 앱을 임의 설치하지 않는다.

Fedora Ghostty 설정에는 활성 옵션이 없고 주석만 있었다. 따라서 내용 없는 Ghostty config를 새로 배포하지 않고 Ubuntu도 기본값을 사용한다. 설치 뒤 사용자 설정이나 로그인 데이터를 저장소에 자동 수집하지 않는다.

## 검증

오프라인 계약 검사는 OS 분기·프로필 경계·기존 설치 보존·다운로드 체크섬·공백 경로·기존 파일 보존을 확인한다. hosted Installation checks에는 기존 Fedora 13개 / Ubuntu 15개 외에 Fedora·Ubuntu·Arch·openSUSE full 22개 CLI + Ghostty·Orca 패키지/AppImage의 cold install·실행·반복 적용을 추가했다. GUI 창·인증·모든 OS의 실제 실행은 CI 성공으로 주장하지 않는다.

openSUSE는 기존 OSS 저장소의 Ghostty를 사용한다. Orca의 공식 AppImage를 사용자 경로에 풀어 실행하는 구현과 체크섬 메타데이터는 Arch와 공유한다. 새 설정 배포·기본값 활성화·서명 예외는 앱 설치에 포함하지 않는다. Zypper 단계는 기존 패키지·vendor를 유지하는 순수 추가 계획만 허용한다.

공통 필수 패키지는 `scripts/lib/packages.py`, 대상별 개인 백업은 `scripts/lib/backup.py`, Mac native provider는 `scripts/lib/macos.py`와 `scripts/macos-providers.json`이 담당한다. `scripts/unix/mise.toml`의 Python은 설치기용이며 global CLI inventory에 중복 선언하지 않는다.
