# AI CLI와 Orca

이 단계에서는 AI 설정·계정·Orca 상태를 가져오지 않았다. 선정한 CLI 설치와 개인 설정 이전은 후속 단계다.

도구마다 공식 설정 경로를 사용한다. 향후 agy는 .gemini/antigravity-cli, Claude는 .claude, Codex는 .codex, OpenCode는 .config/opencode, Pi는 .pi/agent, Kiro는 .kiro, Grok은 .grok에 해당하는 소스를 관리한다. Aider는 필요할 때 .aider.conf.yml을 작성한다. 모든 제품을 하나의 .config/ai 밑으로 강제 이동하지 않는다.

공통 개인 지침은 .chezmoitemplates/ai에서 관리하고 각 제품의 공식 로딩 방식으로 배포한다. 프로젝트 AGENTS.md·CLAUDE.md와 Kiro steering은 해당 프로젝트가 소유한다. 같은 파일명을 복사하면 모든 제품이 자동으로 읽는다고 가정하지 않는다.

앱·Orca가 함께 수정하는 설정은 전체 덮어쓰기 대신 선택한 키만 갱신한다. chezmoi `modify_` 파일은 JSON/TOML 문서가 아니라 변환 스크립트다. 실제 작성 시 파서·실행기·배열 소유권을 검증하며 hooks·기기별 신뢰·미관리 설정을 보존한다.

로그인·토큰·계정·대화·session·자동 memory·cache·Orca Electron 상태·worktree 등록은 Git 배포 대상이 아니다. Orca의 실행 경로는 버전별 설치 절대 경로 대신 검증한 안정 경로를 사용한다.

초기 통합은 CLI 기본 실행과 Orca 터미널 연결을 기준으로 확인한다. 모든 CLI에서 동일한 채팅 UI나 자동 오케스트레이션이 지원된다고 약속하지 않는다. 실험적 오케스트레이션은 별도 필요와 검증이 생긴 후 추가한다.
