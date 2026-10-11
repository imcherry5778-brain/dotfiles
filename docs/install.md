# 최초 설치와 현재 진입점

기본 동작은 계획 출력이고 Check 동작도 읽기 전용이다. install.sh의 `--apply --profile FILE`은 Fedora x86_64 common baseline과 Ubuntu 26.04·Arch·openSUSE Tumbleweed x86_64 desktop/full profile을 지원한다. install.ps1의 Windows 설치는 아직 구현하지 않았다.

## checkout 위치

인증을 준비한 후 원격 저장소를 각 OS의 실제 홈 아래 `projects/imcherry5778-brain/dotfiles`에 clone한다. 예시는 GitHub 계정 권한과 Git 인증이 준비되어 있다는 전제다.

Unix:

```sh
git clone https://github.com/imcherry5778-brain/dotfiles.git "$HOME/projects/imcherry5778-brain/dotfiles"
```

PowerShell:

```powershell
$destination = Join-Path $HOME 'projects/imcherry5778-brain/dotfiles'
git clone https://github.com/imcherry5778-brain/dotfiles.git $destination
```

기존 경로가 있으면 새 clone으로 덮어쓰지 않고 해당 checkout을 확인한다. Git 인증 방식은 기기 설정을 사용하며 전역 인증 공급자를 이 프로젝트가 자동 변경하지 않는다.

## 명시적 프로필 설치의 계약

Git·mise·chezmoi·사용할 셸의 현재 설치를 확인하고 필요한 최소 도구만 확보한다. 그다음 sourceDir를 현재 checkout으로 연결하고 기기 데이터를 초기화한다. sourceDir는 /home 등의 문자열을 하드코딩하지 않고 현재 위치를 사용한다.

`chezmoi init`은 config·source·상태를 만들 수 있고 `chezmoi init --apply`는 대상 파일도 변경한다. 개인 Fedora에서는 별도 사용자 승인과 최신 diff·백업 검토 후 초기화·적용을 완료했다. 아래 common baseline profile은 개인 기기 선택을 대신하지 않는다.

리뷰한 설정 diff와 배포를 분리하고 기존 파일을 보존한다. 프로그램 설치·업그레이드·버전 삭제를 셸 시작이나 chezmoi 자동 훅에 연결하지 않는다. 인증은 각 OS에서 별도로 준비한다.


`tests/profiles/fedora-common.json`은 설치 CI의 명시적 선택 자료다. 모든 개인/AI feature는 false이고 배포·외부 소스만 true다. 현재 개인 Fedora 이전용 profile이 아니다.

```sh
# 승인한 새 Fedora baseline 환경에서만 사용. 실제 사용자 홈을 변경한다.
sh install.sh --apply --profile tests/profiles/fedora-common.json
```

Ubuntu 선택은 tests/profiles/ubuntu-desktop.json에 있다. ai/editor_web=true, 나머지 기능=false이며 공통 13개·OpenCode·Node를 설치한다. 대상 Ubuntu의 OS 패키지는 먼저 준비해야 한다.

```sh
# Ubuntu 26.04에서, diff·백업 검토 후에만 실제 홈에 적용한다.
sudo apt-get install git curl zsh tmux wl-clipboard build-essential bash-completion
sh install.sh --apply --profile tests/profiles/ubuntu-desktop.json
```

기반 Python 3.11+, tar/gzip/unzip·CA 인증서도 필요하다. 기본 CLI profile은 패키지 관리자나 chsh를 호출하지 않는다. full profile의 별도 데스크톱 앱 단계는 패키지 관리자를 사용할 수 있으며 chsh는 호출하지 않는다. 설치 후 기본 셸 전환·GUI 클립보드·LazyVim 플러그인 실행은 실제 기기 검증 단계다. 기존 다른 chezmoi 선택이나 Ubuntu/Arch/openSUSE 권한 정책은 자동 대체하지 않는다.

설치 순서:

1. 일반 사용자·실제 로그인 홈·프로필과 일치하는 Fedora/Ubuntu/Arch/openSUSE x86_64·기본 config/data 위치와 OS 의존성을 검사한다. Git, Python 3.11+, Zsh, tmux, tar, gzip, unzip, Perl, sed, awk은 OS가 제공해야 한다. 사용자 설정·CLI 단계는 패키지 관리자를 실행하지 않는다. desktop=true 선택의 앱 단계는 OS 패키지 관리자를 호출할 수 있다.
2. mise 2026.10.3과 chezmoi 2.73.0이 없으면 공식 실행 파일을 SHA-256 검증 후 ~/.local/bin에 설치한다. 기존 다른 버전이나 충돌 파일은 덮어쓰지 않고 중단한다.
3. 선택 자료로 chezmoi config를 초기화하고 필수 배포 대상이 실제 존재하는지 확인한다. 기존 다른 기기 profile은 자동 변경하지 않는다.
4. global mise 설정을 먼저 적용하고 실제 홈에서 mise install을 실행한다. 공통 버전은 home/dot_config/mise/config.toml, 선택 환경의 추가 버전은 각 config.<environment>.toml이 중복 없이 소유한다.
5. 셸·Git·gh·tmux·Neovim 설정과 고정 external 소스를 적용하고 chezmoi verify를 실행한다.

기존 개인 환경의 이전·백업·복구나 RPM 제거를 자동 수행하지 않는다. 네트워크 또는 설치 오류는 즉시 실패하며 원자적 rollback을 제공하지 않는다. 인증·SSH/GPG 키·Conda는 설치 범위 밖이다. 기본 desktop CLI profile은 OpenCode를 포함하고 full profile은 추가 AI CLI 7개와 Ghostty·Orca 설치를 명시적으로 선택한다. GUI 화면·로그인은 실제 사용자 세션에서 별도로 검증한다. Neovim 플러그인 설치/업데이트는 별도 앱 동작이며 설치 CI에서 완료로 표시하지 않는다.

GitHub Actions의 Installation checks는 GitHub-hosted ubuntu-24.04에서 Fedora baseline·Ubuntu baseline/full·Arch/openSUSE full 컨테이너를 별도 job으로 생성한다. OS 의존성만 root 단계에서 준비하고 실제 설치와 테스트는 dotfiles-test 일반 사용자의 원래 홈에서 실행한다. HOME/XDG를 바꿔 성공시키지 않는다. 공백 경로의 checkout, 빈 tool cache, 실제 CLI 경로, 셸·tmux, 기존 Git/gh 설정 보존, 두 번째 설치의 내용·링크·권한 안정성을 검사한다. 컨테이너를 종료하면 설치 환경은 폐기된다. 사용자 PC에 원격 적용하는 workflow가 아니다.


## 확인한 실행 결과

2026-10-11, 코드 commit `c566f13`의 [Installation checks](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38137704512)가 통과했다. Fedora 44 일반 사용자에서 13개 CLI를 새로 설치하고 모든 실행 파일의 실제 경로·버전을 확인했다. Zsh/tmux runtime와 Neovim Lua 구문 검사 후 같은 진입점을 재실행했고, external 파일을 포함한 managed 경로 1,902개의 내용·링크·권한이 동일하며 chezmoi diff가 비어 있음을 확인했다.

같은 commit의 [Foundation checks](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38137704539)도 Linux·Windows·macOS에서 통과했다. Windows/macOS의 실제 도구 설치 성공을 의미하지 않는다. 당시 실제 Fedora 사용자 홈의 검토 기준 476개 경로와 기존 파일 449개는 변경되지 않았다. 이후 개인 홈 적용 기록은 [Fedora 실제 적용 결과](fedora-application.md)에서 구분한다.

2026-10-11, Ubuntu 지원 코드 commit `55f5402`의 [Installation checks](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38140944752)는 Ubuntu 26.04의 15개 도구와 Fedora 44의 13개 도구를 각각 새로 설치해 두 번 적용했다. 두 환경 모두 실행 경로/버전·Zsh/tmux·기존 설정 보존·반복 적용·빈 diff를 통과했다. 관리 경로는 external을 포함하여 Ubuntu 1,944개·Fedora 1,903개다. 당시 Ubuntu 사용자 홈은 미적용이었으며 이후 실제 적용 결과는 [Ubuntu 적용 기록](ubuntu-application.md)에 있다.

## AI·데스크톱 전체 프로필

기존 Fedora common / Ubuntu desktop CLI profile의 범위는 유지한다. 명시적 Ubuntu·Arch·openSUSE full 선택과 OS 앱 단계는 [AI·데스크톱 설치 자동화](installation-automation.md)에 기록했다. desktop=true인 full profile은 OS 패키지를 설치하므로 sudo가 필요할 수 있다. 설정 적용과 CLI 설치는 계속 일반 사용자로 실행한다.

## Arch x86_64

`tests/profiles/arch-desktop.json`은 15개 CLI, `arch-full.json`은 Ubuntu와 같은 22개 CLI와 Ghostty·Orca를 선택한다. 기존 OS 의존성을 먼저 확인하고 최신 diff·개인 백업을 준비한 다음 실행한다.

```sh
sh install.sh --apply --profile tests/profiles/arch-full.json
```

Arch는 기존 패키지 DB를 사용하며 `pacman -Sy`를 단독 실행하지 않는다. `zsh`, `tmux`, `unzip`, `bash-completion`, `wl-clipboard` 등 OS 의존성과 compiler/build tools를 먼저 준비해야 한다. 개인 기기 적용·기존 설정 보존·기본 셸 전환·GUI 검증 결과는 [Arch 적용 기록](arch-application.md)에 있다. 코드 `56191e3`의 [설치 CI](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38146047528)는 네 설치 profile을 통과했다.

## openSUSE Tumbleweed x86_64

`tests/profiles/opensuse-tumbleweed-desktop.json`은 공통 CLI·OpenCode·Node 15개, `opensuse-tumbleweed-full.json`은 Ubuntu/Arch와 같은 22개 CLI와 Ghostty·Orca를 선택한다. 최신 diff와 기존 설정 백업을 먼저 검토한 뒤 실제 사용자로 실행한다.

```sh
sh install.sh --apply --profile tests/profiles/opensuse-tumbleweed-full.json
```

OS 의존성은 Git(`git-core`), Python 3.11+, Zsh, tmux, Perl, sed, awk, tar/gzip/unzip, curl, CA 인증서, bash-completion, wl-clipboard, gcc/gcc-c++, make다. Ghostty는 공식 OSS 패키지, Orca는 체크섬으로 고정한 공식 AppImage와 그 번들의 CLI를 쓴다. GTK3·CUPS·NSS·secret/audio 등 AppImage 외부 라이브러리는 OS가 제공한다. `install_opensuse_packages`는 기존 저장소 메타데이터로 dry-run XML을 검사하고 추가만 허용한다. 제거·업그레이드·다운그레이드·vendor 변경 계획이 있으면 중단한다. RPM 서명 검사를 우회하지 않는다. 개인 기기 결과와 복구는 [openSUSE 적용 기록](opensuse-application.md)에 있다.
