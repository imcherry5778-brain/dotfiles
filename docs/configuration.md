# 설정과 기기 데이터

공통 기본값은 home/.chezmoidata.toml, 초기 기기 선택은 home/.chezmoi.toml.tmpl, 실제 기기 값은 그 기기의 chezmoi config에 둔다. static 데이터 파일을 템플릿으로 만들지 않는다.

현재 초기화 템플릿은 Linux 배포판 ID, darwin→macos, windows를 정규화하고 기존 platform 선택이 있으면 같은 OS 계열인지 검증한다. 지원하지 않는 플랫폼은 조용히 Fedora로 취급하지 않는다. config의 sourceDir는 실제 Git checkout 루트인 `.chezmoi.workingTree`에서 유도한다. `.chezmoiroot` 적용 후 템플릿의 `.chezmoi.sourceDir`는 home 하위 디렉터리이므로 이를 config sourceDir에 그대로 복사하지 않는다. 검증은 --source 없이 config를 다시 읽어 이 구분을 확인한다.

공유 선택은 AI 기능 사용, Conda 기본 비활성, 기존 도구 보존 기본 비활성이다. 이것은 설치 명령이 아니며 현재 어떤 프로그램도 실행하거나 설정하지 않는다. 기존 Fedora 이전 시 Conda·개인 추가 도구·Bitwarden·서명 연결은 실제 조사 결과에 맞춰 기기별 값을 보존해야 한다.

현재 `.chezmoiignore`의 `**`는 단계 경계다. 실제 파일을 들여오는 변경에서 필요한 대상과 문서 제외 규칙을 검토하며 제거/교체한다. 일반 설정을 아직 확인하지 않은 상태에서 배포 대상을 활성화하지 않는다.

## 목표 대상 예시

| 소스 | 실제 대상/역할 |
|---|---|
| home/dot_zshrc.tmpl | ~/.zshrc |
| home/dot_gitconfig.tmpl | ~/.gitconfig |
| home/dot_config/mise/config.toml | ~/.config/mise/config.toml |
| home/dot_config/powershell/profile.ps1.tmpl | 실제 PowerShell 프로필에서 연결할 공통 본문 |
| home/dot_claude/CLAUDE.md.tmpl | 개인 Claude 지침 |
| home/dot_codex/AGENTS.md.tmpl | 개인 Codex 지침 |
| home/.chezmoitemplates/ai/instructions.md.tmpl | 여러 개인 지침의 원문 조각 |

위 대상은 아직 추가하지 않았다. PowerShell 실제 프로필은 `$PROFILE.CurrentUserAllHosts`로 확인한다. 일반 설정은 chezmoi 복사/렌더링을 사용하고 링크는 기존 Oh My Tmux처럼 이유가 있는 대상에서만 유지한다.
