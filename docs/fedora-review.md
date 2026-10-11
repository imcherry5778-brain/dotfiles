# Fedora 설정 검토와 변경 판단

확인일: 2026-10-11. 실제 사용자 설정과 설치 경로를 다시 읽어 구성한 **배포 전 초안**이다. Fedora 홈에 적용하거나 프로그램을 설치·업그레이드하지 않았다. 파티션·GRUB·VM·시스템 설정은 대상 밖이다.

## 유지·변경·제외

| 대상 | 유지할 것 | 변경할 것과 이유 |
|---|---|---|
| Zsh | robbyrussell, 14개 플러그인의 상대 순서, history 50,000, vi/vim/y/ssh alias, Ctrl+X Ctrl+H, agy의 TMUX 우회 | 사용자 홈·SUDO_EDITOR의 버전 경로 제거. PATH를 배열로 중복 제거. 선택한 플러그인·파일·실행 파일의 존재를 검사하여 누락 시 셸이 열리게 함 |
| 초기화 소유자 | mise·fzf·zoxide는 기존 OMZ 플러그인이 담당 | 별도 eval을 추가하지 않음. mise의 활성화를 fzf/zoxide 앞에 유지 |
| GPG TTY | 터미널에서의 GPG_TTY 연결 | TTY가 있을 때만 tty 실행. 비 TTY의 문자열을 GPG_TTY에 넣지 않음 |
| Bitwarden | 현재 Flatpak SSH agent 연결 의도 | 소켓 경로를 기기 데이터로 렌더링. 없는 소켓이 자동으로 생긴다고 가정하지 않음 |
| Conda/Mamba | 기존 두 hook과 fallback 동작 | 기기 선택과 prefix 데이터로 표현하고 실행 파일 누락 시 생략. 이후 conda init이 managed rc를 다시 수정하지 않도록 소유권 명시 |
| Git | 현재 이름·이메일·서명키·commit.gpgsign·빈 helper 초기화 항목·알 수 없는 설정 | modify 템플릿으로 공통 include만 추가하고 낡은 gh 버전 경로를 안정적인 mise shim으로 교체. 공백 경로 quoting 검증 |
| Git/gh 공통 | main, nvim 선택, 기존 Claude 로컬 설정 ignore, gh의 HTTPS·co alias | 다른 gh alias·prompt·미관리 키·빈 scalar·주석을 보존하는 검증된 YAML 줄 갱신. hosts.yml은 대상 아님 |
| mise | 기존 28개 도구를 다른 공급자로 일괄 교체하지 않음. aws-cli의 symlink_bins 유지 | 공통 13개·AI 1개·Fedora 추가 20개로 단일 소유권 분리. 현재 확인 버전으로 고정. 실제 설치는 별도 단계 |
| tmux | Ctrl+Space, mouse, 50,000줄, extended-keys, allow-passthrough, copycat/resurrect, 복구 프로세스 목록 | 시작·reload 시 플러그인 자동 갱신/자동 제거를 false로 변경. 기존 upstream revision을 기록하고 명시적 관리로 이전 |
| Neovim | 실제 수정된 Lua, lazy-lock.json, LazyVim 설정·라이선스, 웹·Python 작업 구성 | 비활성 example.lua와 starter README/.git을 공유 대상에서 제외. editor_web 선택으로 extras import와 웹 LSP 선언을 함께 제어 |
| 자동완성 | compinit 전 경로 등록, Conda 뒤 공급자 등록, 선택형 carapace·native·argcomplete·보정 코드 | PATH 등록을 rc 한 곳으로 모음. 캐시·fingerprint·manifest·검사 결과는 제외 |
| Claude/Codex/OpenCode | 실제 개인 선호 값 | JSON/TOML 부분 갱신으로 hooks·MCP·프로젝트 신뢰·미관리 키 보존. 앱 상태 전체는 수집하지 않음 |

OMZ와 tmux 자동 갱신을 끄는 것은 의도적인 동작 변경이다. 단순 파일 정리가 아니다. 플러그인은 기록한 revision 기준이며 갱신 명령은 아직 구현하지 않았다. Neovim의 기존 업데이트 검사와 LazyVim 자체 bootstrap 동작은 이번에 변경하지 않았다.

## CLI 선언과 설치의 구분

`home/dot_config/mise/config.toml`에 공통 13개, `config.ai.toml`에 기존 mise-owned OpenCode 1개, `config.personal-fedora.toml`에 나머지 기존 도구 20개가 있다. Fedora 선택은 `miserc.toml`에서 ai/personal-fedora로 명시한다. 단순히 환경 파일을 만들어 놓은 것으로 활성화됐다고 하지 않는다.

rg/fd/bat/jq는 RPM, carapace는 수동 바이너리인 현재 상태를 유지했다. 해당 버전을 mise 선언에 넣었으나 공급자가 실제로 전환된 상태는 아니다. delta 0.20.1은 공식 최신 릴리스에서 확인한 **신규 설치 후보**이며 설치하거나 pager로 활성화하지 않았다. `features.delta=false`가 기본값이다.

기존 floating latest/계열을 확인된 설치 버전으로 고정했다. 이후 업데이트는 의도적으로 버전 선언을 바꾸는 절차가 된다. OS별 다운로드 artifact와 checksum을 담은 mise lockfile은 아직 만들지 않았다. 현재 버전 선언과 config 선택 검증을 설치 성공·완전한 공급망 잠금으로 해석하지 않는다. 원본 설치 버전과 분류는 [inventory](fedora-inventory.json)에 기록했다.

## 자동완성의 정확한 경계

404개 YAML 모두 `$carapace.bridge.Bash(...)` 규칙이다. 사용자 선택을 담은 어댑터라서 그대로 관리한다. 작은 파일을 숫자만 줄이려고 합치면 기존 사용자 spec을 재현하는 별도 생성/배포 계약이 필요하므로 이번 이전에서는 추가하지 않았다.

26개 native 파일은 캐시 본문이 아니라 CLI 생성기에 연결하는 얇은 사용자 어댑터다. 버전별 실제 completion/cache는 공유하지 않는다. 로더와 보정 표는 선언/구현으로 관리하고 manifest.json·verification.json은 기기 검사 기록으로 제외한다.

community 50개 중 47개는 설치된 zsh-completions revision과 바이트가 같다. 고정 revision의 외부 파일 선언으로 재현한다. 나머지 _cmake·_golang·_sox_ng는 #compdef 첫 줄이 바뀐 사용자 패치다. 이 세 파일만 선택적으로 가져오고 기존 copyright/license 헤더를 유지했다. 50개 파일을 새 OS에 일괄 배포하지 않는다.

fzf-tab은 독립 .git이 없는 설치본이다. 상위 OMZ의 Git SHA를 fzf-tab SHA로 잘못 사용할 수 있었다. 공식 v1.3.0 tree의 모든 blob과 설치 파일을 비교해 동일함을 확인했다. 외부 선언에는 해당 commit을 사용한다.

Fedora completion은 bash-completion의 /usr/share·/etc 공급자와 기존 shtab 1.7.2·ai-cli 파서에 의존한다. shtab 환경과 ai-cli 패키지를 함께 옮기거나 설치하지 않았다. 기존 Fedora에서는 유지하고 재설치 bootstrap에서는 의존성을 별도로 준비해야 한다. 모든 CLI의 실제 Tab 동작을 이번에 전수 재검증한 것은 아니다.

## 관리하지 않는 파일

- Ghostty config는 주석만 있어 활성 취향이 없다. 새 글꼴·테마·알림 정책을 넣지 않는다.
- lazygit의 빈 config와 기본값을 쓰는 Yazi/bat/fd/rg/uv config는 만들지 않는다.
- .bash_profile은 배포판 기본 .bashrc 연결, .profile은 빈 파일이다. 둘 다 그대로 두고 관리 대상에서 제외한다. 새 .zprofile/.zshenv도 만들지 않는다.
- SSH config의 asus·ds224p는 기기 연결 정보다. 이번 공통 source에 넣지 않으며 현재 파일을 그대로 유지한다. SSH/GPG 키·known_hosts·agent 상태는 수집하지 않는다.
- Pi의 lastChangelogVersion은 표시 상태다. Aider/Kiro/Grok 등에는 현재 공유할 사용자 설정이 확인되지 않아 빈 파일을 만들지 않는다. agy 설정·로그인 파일 전체를 복사하지 않는다.
- Kiro의 cli.json은 빈 객체다. agy의 allowNonWorkspaceAccess/toolPermission은 기기 권한 선택으로 남긴다. .gemini/GEMINI.md는 Context7 표시 구간으로 구성된 모듈 지침이므로 새 공통 개인 지침으로 복제하지 않는다. 현재 개인 .codex/AGENTS.md와 .claude/CLAUDE.md는 없다.
- 개인 AGENTS.md/CLAUDE.md, 사용자 scripts 전체, 모든 skills/plugins, Orca GUI 상태를 자동 수집하지 않는다. 기존 내용과 재사용 범위를 별도로 검토해야 한다.

## 부분 갱신과 남은 검증

chezmoi modify-template 파일은 .tmpl 확장자를 쓰지 않는다. AI JSON/TOML과 gh YAML은 관리 값이 이미 같으면 원문을 그대로 반환한다. 현재 Fedora의 세 AI 설정과 gh는 내용 변경이 없다. AI 값 변경 시에는 미관리 값을 보존하며 재출력하므로 주석·키 순서·포맷이 바뀔 수 있다. gh 값 변경 시에는 일반 block YAML의 선택한 줄만 바꾸고 전체 의미를 비교한다. 안전하게 수정할 수 없는 형태는 덮어쓰지 않고 중단한다. 잘못된 문서는 조용히 빈 기본값으로 덮지 않고 파싱 오류로 중단한다. 실제 인증·Orca 연동은 실행하지 않았다.

Git 사용자 identity와 서명 정책은 유지한다. signing key의 UID/email과 GitHub 서명 검증 일치는 별도 확인 대상이며, 이번 초안이 그것을 수정하거나 보장하지 않는다. Neovim의 기존 별도 .git과 미커밋 파일도 제거하지 않았다.

배포는 기본 비활성이고 Fedora만 preview 대상으로 구현했다. 설치 전 파일별 diff·복구본, mise shim 존재, Conda prefix·SSH socket, tmux upstream/플러그인·completion 의존성, 실제 앱 동작을 확인해야 한다. 이번에 Windows/macOS용 실사용 설정까지 완료한 것으로 표시하지 않는다.

실행한 검증은 [테스트 문서](../tests/README.md)를 따른다. 반복 적용·부분 갱신·미관리 키 보존·34개 도구 선택·셸 문법을 검사했다. Fedora에서는 기존 OMZ 복사본과 모형 CLI를 네트워크 차단·읽기 전용 host·임시 home mount로 실행하여 14개 플러그인 순서, 단일 activation, PATH 재로딩, OMZ 누락 시 fallback을 확인했다. 실제 CLI·인증·전수 Tab 검증과 구분한다.

실제 Claude/Codex/OpenCode config에 대해서도 read-only cat 결과를 메모리에서 파싱해 비교했다. 선택한 선호 값 외 모든 기존 값이 유지됨을 확인했으며 결과 config를 저장하거나 적용하지 않았다. Neovim Lua는 -u NONE으로 플러그인 없이 구문만 컴파일했다. stylua.toml과 lazyvim.json의 source에는 마지막 줄바꿈만 정규화했다.

## 실제 diff 검토 후 초안 수정

gh 2.102.0 실제 파서로 빈 `editor`·`browser`·`pager`·`http_unix_socket`를 읽는 검증을 추가했다. 이전 YAML 재출력은 이 값들을 문자열 `"null"`로 바꿨으며 수정 초안은 빈 값으로 유지한다. 원문 no-op, 주석/미관리 alias 보존, 비지원·잘못된 입력 중단을 격리 홈에서 검사한다.

`.local/share` 700과 gh config 600의 권한 완화를 제거했다. gh 디렉터리는 751에서 700으로 제한하는 제안이다. 기존 디렉터리 권한까지 두 번째 적용 후 그대로인지 검사한다. 권한 구성 이유는 [configuration](configuration.md)에 기록했다. Neovim lazy.lua의 불필요한 공백 차이도 제거했다.

실제 Fedora preview는 파일/링크 476개 중 기존 내용 변경 12개·새 파일 4개·내용 동일 460개다. gh와 세 AI 문서는 내용이 동일하다. `.local/share`와 gh 파일 권한도 현재와 동일하다. 삭제 선언이나 외부 다운로드는 없다. 이 수치는 기기 기능을 명시적으로 켠 기존 Fedora 프로필 기준이며 실제 적용을 뜻하지 않는다.

mise에 아직 설치하지 않은 ripgrep/fd/bat/jq/carapace/delta 6개는 이후 적용 준비에서 처리해야 한다. 현재 RPM과 수동 바이너리는 유지하며 설치·공급자 전환·delta pager 활성화는 하지 않았다. 수정 초안이 검증됐다는 것을 모든 설치 작업 완료로 해석하지 않는다.
