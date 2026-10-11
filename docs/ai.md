# AI CLI와 Orca

Fedora에서 실제 공유할 선호만 source로 구성했다. Claude는 dark/fullscreen, Codex는 현재 gpt-6.1-sol/high/priority, OpenCode는 autoupdate=false를 유지한다. Codex 모델을 다른 모델로 변경하지 않는다. 이는 모든 OS의 모델 접근·요금·실행 성공을 보장하지 않는다.

각 source는 chezmoi modify-template이다. 기존 JSON/TOML을 파싱하고 선택한 키만 갱신한다. hooks·MCP·프로젝트 신뢰·플러그인·알 수 없는 키와 Claude statusLine은 보존한다. 이 키들의 실제 값과 인증 데이터는 source로 수집하지 않았다. 선호 값이 이미 같으면 입력 원문을 그대로 반환해 주석·키 순서·포맷도 보존한다. 값 변경이 필요한 재출력에서만 주석과 키 순서가 바뀔 수 있다.

Pi의 changelog 버전은 실행 상태로 제외했다. 나머지 agy/Aider/Kiro/Grok에는 이번에 관리할 사용자 선호 파일을 새로 만들지 않았다. 로그인·토큰·계정·세션·자동 memory·Orca Electron 상태·worktree 등록은 제외한다. 개인 지침과 모든 skills/plugins를 통째로 수집하지 않는다.

OpenCode의 shared 설치 선언은 그대로 두고 Ubuntu의 명시적 managed_ai 선택에서 추가 7개를 mise로 설치한다. Fedora 기존 공급업체/uv 설치는 그대로 유지한다. Ghostty·Orca는 별도 native 패키지 단계가 담당한다. [공급자·구조·실행 계약](installation-automation.md)을 따른다. Orca 상태·인증·repo/worktree 등록은 복제하지 않는다.

pi npm 설정은 `allow_builds = false`로 설치 스크립트 차단을 명시한다. mise 2026.10.3 기본 npm 설치기는 내장 aube이므로 외부 npm 프로세스용 `install_env.npm_config_ignore_scripts`는 무시된다. [공식 npm backend 문서](https://mise.jdx.dev/dev-tools/backends/npm.html#build-scripts-and-supply-chain-checks)와 고정 버전 원본을 확인해 잘못된 옵션을 제거했다. pi 버전·공급자·실제 실행 동작은 유지하며 기존 Ubuntu 개인 설정은 이번 Arch 작업에서 적용하지 않는다.
