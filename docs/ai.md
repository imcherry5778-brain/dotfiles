# AI CLI와 Orca

Fedora에서 실제 공유할 선호만 source로 구성했다. Claude는 dark/fullscreen, Codex는 현재 gpt-6.1-sol/high/priority, OpenCode는 autoupdate=false를 유지한다. Codex 모델을 다른 모델로 변경하지 않는다. 이는 모든 OS의 모델 접근·요금·실행 성공을 보장하지 않는다.

각 source는 chezmoi modify-template이다. 기존 JSON/TOML을 파싱하고 선택한 키만 갱신한다. hooks·MCP·프로젝트 신뢰·플러그인·알 수 없는 키와 Claude statusLine은 보존한다. 이 키들의 실제 값과 인증 데이터는 source로 수집하지 않았다. 선호 값이 이미 같으면 입력 원문을 그대로 반환해 주석·키 순서·포맷도 보존한다. 값 변경이 필요한 재출력에서만 주석과 키 순서가 바뀔 수 있다.

Pi의 changelog 버전은 실행 상태로 제외했다. 나머지 agy/Aider/Kiro/Grok에는 이번에 관리할 사용자 선호 파일을 새로 만들지 않았다. 로그인·토큰·계정·세션·자동 memory·Orca Electron 상태·worktree 등록은 제외한다. 개인 지침과 모든 skills/plugins를 통째로 수집하지 않는다.

OpenCode의 shared 설치 선언은 그대로 두고 Ubuntu의 명시적 managed_ai 선택에서 추가 7개를 mise로 설치한다. Fedora 기존 공급업체/uv 설치는 그대로 유지한다. Ghostty·Orca는 별도 native 패키지 단계가 담당한다. [공급자·구조·실행 계약](installation-automation.md)을 따른다. Orca 상태·인증·repo/worktree 등록은 복제하지 않는다.

pi npm 설정은 `allow_builds = false`로 설치 스크립트 차단을 명시한다. mise 2026.10.3 기본 npm 설치기는 내장 aube이므로 외부 npm 프로세스용 `install_env.npm_config_ignore_scripts`는 무시된다. [공식 npm backend 문서](https://mise.jdx.dev/dev-tools/backends/npm.html#build-scripts-and-supply-chain-checks)와 고정 버전 원본을 확인해 잘못된 옵션을 제거했다. pi 버전·공급자·실제 실행 동작은 유지하며 기존 Ubuntu 개인 설정은 이번 Arch 작업에서 적용하지 않는다.

## Copilot CLI 설치 선언

2026-10-27 추가. Copilot **CLI만** 설치 대상으로 선언하며 GitHub Copilot 데스크톱은 포함하지 않는다. 로그인·토큰·`~/.copilot` 설정과 세션은 수집·배포·삭제하지 않는다. 실제 CLI가 이미 있으면 기존 설치 주체·버전·실행기를 보존한다. Unix의 실행 버전 확인에는 임시 HOME을 사용하고, Windows는 기존 native 도구 검증 단계에서 `--no-auto-update --version`을 사용한다. VS Code `copilot-shim`은 CLI 설치로 인정하지 않는다.

| OS | 선언과 설치 주체 |
| --- | --- |
| Linux, `features.ai=true` | `scripts/copilot-release.json`의 공식 standalone archive 1.0.103과 SHA256. `scripts/lib/copilot.py`를 Unix 설치기의 after 단계에서 호출한다. 신규 설치는 `~/.local/bin/copilot`에 실행 파일만 추가한다. |
| Windows | `home/.chezmoidata/windows.json`의 `native` 목록, WinGet `GitHub.Copilot`, manifest 버전 **v1.0.103**. bootstrap·mise·vendor script 목록에 중복 선언하지 않는다. |
| macOS | 기존 native adapter와 `scripts/macos-providers.json`의 Homebrew cask `copilot-cli`. 기존 설치를 업그레이드하지 않고, 미설치 시 현재 cask를 설치한다. |

Linux archive는 버전별 URL·SHA256·단일 정규 파일·ELF·실행 버전을 검증한 뒤 대상이 없을 때만 추가한다. 공백 경로와 반복 실행을 지원하며 다른 파일이나 설치 중 새로 생성된 대상을 덮어쓰지 않는다. 현재 Fedora의 ai-cli 관리 실행기와 `--no-auto-update` 정책도 그대로 보존한다. 다른 기기에 ai-cli/sys-update 자체를 복제하거나 배포하는 변경은 아니다. 신규 standalone와 Homebrew/WinGet 설치본의 이후 갱신 정책은 각 공급자의 기본 동작을 따르며 dotfiles apply는 기존 버전을 강제로 되돌리지 않는다.

검증: `python3 -B tests/verify-copilot.py -q`는 격리 HOME·가짜 archive/명령으로 Linux 설치·보존·거부 동작과 Mac 공급자 선택을 검사하고, 실제 chezmoi로 Windows 계획을 렌더링한다. 현재 Fedora 실제 CLI의 보존·실행 버전을 확인했다. 다른 Linux·Windows·Mac의 신규 실제 설치나 인증을 검증했다는 의미는 아니다. 이번 로컬 검증 환경에는 PowerShell이 없어 Windows native 명령 실행은 하지 않았다.

공식 근거: [설치 방법](https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/install-copilot-cli), [Linux archive 릴리스](https://github.com/github/copilot-cli/releases/tag/v1.0.103), [WinGet manifest](https://github.com/microsoft/winget-pkgs/blob/master/manifests/g/GitHub/Copilot/v1.0.103/GitHub.Copilot.installer.yaml), [Homebrew cask](https://formulae.brew.sh/cask/copilot-cli).
