# 설정 source 검증

기반 검증과 Fedora 설정 source의 격리 검증을 구분한다. 기반 검증은 앱 설치·인증·GUI를 검사하지 않는다. 별도 Installation checks의 실제 설치 범위는 아래에 명시한다.

`verify.ps1`은 PowerShell 7과 Git, 지정한 chezmoi 실행 파일을 사용한다. PowerShell은 Windows의 기본 구현이며 이 검증 스크립트에서는 Linux/macOS CI에서도 같은 테스트를 실행하기 위해 사용한다. PowerShell을 Linux/macOS 사용자 기본 CLI 목록에 추가한다는 의미는 아니다.

```powershell
./tests/verify.ps1 -Chezmoi /path/to/chezmoi
```

이미 설치된 chezmoi가 있으면 인자를 생략할 수 있다. 검증기는 도구를 자동 다운로드하지 않는다. CI의 `fetch-chezmoi.ps1`은 별도 명시한 임시 경로에 공식 고정 버전을 내려받아 저장된 SHA-256을 확인한다.

검증 범위:

- PowerShell 구문과 해당 OS의 기본 진입점.
- 공백이 있는 checkout과 대상 경로.
- Fedora·Ubuntu·Arch·openSUSE·macOS·Windows 템플릿 fixture.
- 지원하지 않는 플랫폼과 OS/플랫폼 불일치 거부.
- 현재 러너에서 실제 init와 반복 init의 config 안정성.
- home 안의 공유 데이터와 checkout sourceDir 연결.
- 현재 배포 대상과 diff가 비어 있는지 확인.
- 임시 홈에서만 두 번 apply해 기존 파일·디렉터리가 그대로인지 확인.

원본 checkout, 실제 chezmoi config/cache/state, 사용자 홈을 초기화나 apply 대상에 사용하지 않는다. 테스트의 config·state·cache·source 사본·대상은 전부 임시 디렉터리에 둔다. fixture는 템플릿 자료를 모의할 뿐 해당 OS에서 실행한 검증을 대체하지 않는다.

## Fedora source

Python 3.11+, Zsh, Bash, Git과 지정한 chezmoi를 사용한다.

```sh
python3 tests/verify-fedora.py --chezmoi /path/to/chezmoi --gh /path/to/gh
```

임시 홈에 Fedora draft를 두 번 적용해 idempotence, 공백 경로, 미관리 파일 보존, Git identity·서명 정책 보존, gh alias·빈 scalar·주석 보존, AI hooks·MCP·미관리 키·no-op 원문 보존, 파일/디렉터리 권한의 재적용 안정성, 34개 도구의 단일 소유권, 셸 문법을 검사한다. 외부 선언은 텍스트로만 렌더링하고 다운로드하지 않는다. Fedora/Ubuntu/Arch/openSUSE 외 OS에서는 preview를 켜도 대상이 생기지 않는 경계도 검사한다.

기존 mise가 있으면 `--mise /path/to/mise`로 격리한 config 디렉터리에서 global environment 3개와 34개 도구 선택을 실제 mise로 확인할 수 있다. 설치 명령은 실행하지 않는다.

`--neovim /path/to/nvim`은 사용자 init와 플러그인을 로드하지 않고 렌더링한 Lua 파일의 구문만 컴파일한다. config/data/state/cache는 임시 경로를 사용한다.

Linux에서 기존 OMZ와 bubblewrap이 있으면 `--oh-my-zsh /path/to/existing/oh-my-zsh`를 추가할 수 있다. 기존 OMZ·선별된 completion을 임시로 복사하고 host root는 읽기 전용, 네트워크는 차단, 실제 HOME 경로는 임시 홈으로 mount한다. HOME 환경변수를 다른 값으로 지정하지 않는다. CLI는 모형으로 실행하므로 이 테스트는 초기화 소유권·플러그인 순서·누락 시 fallback을 확인하며 실제 CLI 자체를 검증하지 않는다.

CI는 세 OS의 기본 검증과 Linux 러너의 Fedora source 검증을 실행한다. Linux 러너에 설치하는 Zsh는 일회성 테스트 의존성이며 사용자 Fedora 설치가 아니다. optional mise/OMZ runtime 검사는 현재 Fedora의 격리 환경에서 별도로 실행했다.

`--gh /path/to/gh`는 기존 GitHub CLI의 실제 config 파서로 editor/browser/pager/http_unix_socket의 빈 값과 HTTPS 설정을 확인한다. `GH_CONFIG_DIR`은 임시 fixture 디렉터리만 가리키며 인증 명령이나 실제 계정 파일은 사용하지 않는다. Linux CI도 러너의 gh로 이 검사를 실행한다. gh의 변경된 flow YAML처럼 안전한 줄 갱신을 보장하지 못하는 입력과 잘못된 YAML은 원문을 덮어쓰지 않고 실패하는지 검사한다.

현재 Fedora의 실제 경로를 유지한 읽기 전용 mount preview는 로컬 검토 기록이며 저장소 fixture 검사와 구분한다. mise selector의 기기 실제 경로 동작, 실제 completion 본문, tmux GUI/clipboard 같은 범위는 fixture 성공만으로 보장하지 않는다.


## GitHub-hosted Fedora/Ubuntu/Arch/openSUSE 설치 검증

`.github/workflows/install.yml`의 Installation checks는 ubuntu-24.04 hosted runner에서 각 job의 `tests/containers/<platform>.Dockerfile`을 빌드한다. Self-hosted runner, 호스트 홈 mount, privileged 컨테이너, 설치 cache 재사용은 사용하지 않는다. 기존 Foundation checks는 세 OS에서 계속 실행한다.

`tests/test-install.py`는 해당 일회성 컨테이너의 dotfiles-test 일반 사용자만 허용한다. 다른 환경에서는 설치 전에 중단한다. CI는 install.sh의 실제 --apply 진입점을 두 번 사용한다.

- 고정 mise/chezmoi 다운로드와 체크섬 검사, 중복 없는 mise inventory의 Fedora 13개·Ubuntu 15개 CLI 실제 설치.
- 실제 mise 선택과 설치 경로·버전 확인. 시스템에 이미 있는 바이너리로 대체되면 실패.
- 배포 대상이 실제 존재하는지 검사. 전부 ignored인 빈 apply는 성공으로 인정하지 않음.
- 고정 OMZ·Zsh 플러그인·Oh My Tmux·TPM 소스 배포와 PTY의 실제 Zsh 실행, 별도 tmux 서버·플러그인 바인딩 확인.
- Neovim 실행 파일과 적용된 Lua 구문 확인. Neovim 플러그인 설치/GUI 검증으로 해석하지 않음.
- Git identity·서명 정책·미관리 gh 설정 보존, 두 번째 설치 후 모든 managed 내용·링크·권한 동일, diff 비어 있음.

기본 profile은 `tests/profiles/fedora-common.json`·`ubuntu-desktop.json`, 전체 profile은 Ubuntu·Arch·openSUSE의 `*-full.json`이다. template fixture 디렉터리와 분리한다. 개인 Fedora 34개 도구, 인증·GUI와 Windows/macOS의 실제 설치는 이 검사 범위가 아니다. full profile은 AI CLI 8개를 포함한 22개 CLI와 Ghostty·Orca 설치도 검사한다. Actions job의 read-only GITHUB_TOKEN은 다운로드에만 쓰고 앱 runtime 검사 환경에서는 제거한다.

Ubuntu source 검사: python3 tests/verify-desktop.py --chezmoi /path/to/chezmoi. 실제 홈 대신 공백 경로의 임시 대상으로 초기화 config를 영속화하고, 원본 Bash·profile/logout 보존·단일 추가 라인·권한·반복 적용·15개 도구 단일 소유권·Fedora 기능 거부를 검사한다. 외부 10개 archive 선언은 렌더링만 한다. 설치 CI는 실제 archive를 내려받고 Ubuntu native completion·history·alias 및 사용자 정의가 보존되는지, .config/.local/.local/share 700과 로그인 셸이 유지되는지도 확인한다.

AI/native 앱 확장은 `python3 tests/verify-installers.py`로 오프라인 계약을 검사한다. Ubuntu full source 검증과 22개 CLI·Ghostty/Orca native 패키지 cold install은 기존 baseline 검사와 분리했다. GUI와 로그인을 CI에서 검증했다고 표시하지 않는다.

Arch: `verify-desktop.py --chezmoi /path/to/chezmoi --platform arch`로 Ubuntu와 동일한 보존 검증을 재사용한다. Arch full 프로필은 hosted runner의 새 Arch 컨테이너에서 22개 도구, 공식 Ghostty 패키지와 Orca AppImage/번들 CLI를 설치하고 재실행한다. GUI 검증은 실제 Arch 세션에서 별도 수행한다.

openSUSE: `verify-desktop.py --chezmoi /path/to/chezmoi --platform opensuse-tumbleweed`로 원본 SUSE Bash/profile 보존과 같은 공통 source 계약을 검사한다. 별도 full 설치 job은 Tumbleweed 최소 컨테이너의 GTK3/CUPS 라이브러리와 tmux의 Perl/awk를 명시적으로 준비하고 22개 CLI·Ghostty·Orca 실행·native Bash·Zsh/tmux·반복 설치를 검증한다. Zypper solver의 추가 허용과 제거/upgrade/downgrade/vendor 변경 거부는 `verify-installers.py`에서 검사한다. 코드 `c84169a`의 [설치 CI](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38154063232)는 다섯 job을 통과했고 [기반 CI](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38154063296)도 통과했다. 실제 KDE·클립보드·편집기 플러그인 검증은 [개인 기기 기록](../docs/opensuse-application.md)에서 구분한다.

## Native Windows 설정 검증

Windows에서 `./tests/verify-windows.ps1`을 실행한다. WinGet 설치 자체와 분리된 격리 대상 검사이며, 공백이 있는 checkout/home, Windows 파일명, AppData 대상, 기존 PowerShell 프로필과 5.1 설정·AI 훅 보존, provider 단일 소유권, 반복 apply의 바이트 안정성과 렌더링 PowerShell 구문을 검사한다. Foundation checks의 Windows hosted job에서도 실행한다. 실제 설치 계약은 [Windows 문서](../docs/windows.md)를 참고한다.

## Whole installation contract

`tests/run-install.sh` prepares mise-managed Python before Linux acceptance tests.
Minimal Dockerfiles provide clone/network/admin essentials; installer-owned prerequisites
are installed by the installer. `verify-regression.py` checks the five existing profile
renders against `profile-regression.json`, recorded from the pre-Mac source. Blank-only
format changes and the explicitly preserved, separate OpenCode bump are normalized.
Changes to target lists, other configuration content and provider declarations fail.

`windows-install.ps1` starts from native PowerShell 5.1 in the actual hosted user home,
uses Microsoft's WinGet bootstrap when the runner lacks it, and installs/repeats the CLI
profile. Orca's interactive GUI and authentication remain outside this CI profile.
`macos-install.sh` runs ARM64 full installation and repeat/login-shell checks in the
actual hosted Mac home. Both scripts refuse non-hosted environments. Neither is a
remote deployment workflow or a self-hosted runner. Personal Mac GUI/clipboard checks
are recorded separately in docs/macos-application.md.

## chezmoi 중심 개편 검증

`verify-automation.py --chezmoi /path/to/chezmoi`는 실제 init --apply와 apply를 격리 대상으로 실행한다. provider runner만 테스트 관찰기로 대체하고 production 전후 템플릿을 그대로 사용해 실행 순서, 반복 실행, diff/dry-run의 비실행, 부모 DB 잠금 중 별도 읽기 state 조회, 초기화 프로필 충돌 거부를 확인한다. hosted 설치 테스트는 production provider를 실제 실행하고 fd 실행 파일을 삭제한 뒤 일반 apply로 복구되는지 확인한다. Fedora full은 22개 CLI와 Ghostty·Orca를 포함하며 개인 Fedora 프로필과 분리한다. 설정 diff는 `--exclude=scripts`로 비교한다.
