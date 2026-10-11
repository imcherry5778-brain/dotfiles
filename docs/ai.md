# AI CLI와 Orca

Fedora에서 실제 공유할 선호만 source로 구성했다. Claude는 dark/fullscreen, Codex는 현재 gpt-6.1-sol/high/priority, OpenCode는 autoupdate=false를 유지한다. Codex 모델을 다른 모델로 변경하지 않는다. 이는 모든 OS의 모델 접근·요금·실행 성공을 보장하지 않는다.

각 source는 chezmoi modify-template이다. 기존 JSON/TOML을 파싱하고 선택한 키만 갱신한다. hooks·MCP·프로젝트 신뢰·플러그인·알 수 없는 키와 Claude statusLine은 보존한다. 이 키들의 실제 값과 인증 데이터는 source로 수집하지 않았다. 주석과 키 순서는 재출력 시 바뀔 수 있다.

Pi의 changelog 버전은 실행 상태로 제외했다. 나머지 agy/Aider/Kiro/Grok에는 이번에 관리할 사용자 선호 파일을 새로 만들지 않았다. 로그인·토큰·계정·세션·자동 memory·Orca Electron 상태·worktree 등록은 제외한다. 개인 지침과 모든 skills/plugins를 통째로 수집하지 않는다.

현재 mise-owned AI 설치 선언은 기존 OpenCode 하나다. 8개 AI CLI를 모두 재설치하는 자동화는 구현하지 않았다. 기존 공급업체/uv 설치는 현재 그대로 유지한다. Orca 실행 경로·훅·실제 CLI 연동은 적용 단계에서 별도로 검증한다.
