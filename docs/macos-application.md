# Mac 적용 기록

이번 작업의 실제 변경 대상은 `ssh mac`의 Apple Silicon Mac 하나다. 저장소와 CI는 모든 지원 OS에 대해 보완하지만 기존 다섯 OS 설정은 다시 적용하지 않는다. 아래는 구현 계약이며 실제 적용 결과는 검증 완료 후 추가한다.

## 확인한 기존 환경

macOS 27.0.1 ARM64, Homebrew 7.0.8, mise 2026.9.16, Node 24.21.0, pnpm 12.9.1, tmux 3.7c. Xcode·Oh My Zsh·Ghostty·D2Coding·Bitwarden이 존재했다. agy·Claude·Codex는 Homebrew cask 설치를 유지한다. 기존 pnpm Node 파일은 삭제하지 않고 mise Node가 우선하도록 shell PATH를 구성한다.

## 구성과 보존

공통 CLI 13개와 OpenCode는 공통 mise 선언을 재사용한다. Mac 전용 config에 기존 Node·pnpm·tmux와 공식 Pi npm package, uv 격리 Aider를 둔다. Linux용 AI binaries/completion은 배포하지 않는다. Kiro/Grok은 검토한 공식 Mac 설치기로 추가한다. Ghostty·폰트·Orca는 직접 Homebrew cask로 설치하며 기존 앱은 보존한다.

Zsh/OMZ·tmux·LazyVim·Git·CLI와 선택 AI 키는 chezmoi가 관리한다. AI 인증·hooks·추가 키는 selective modify로 유지한다. `.zprofile`의 Hermes 경로를 유지하며 Homebrew shellenv만 중복 없이 추가한다. 유효한 SSH 전달 socket을 우선하고 없을 때 기존 Bitwarden socket을 사용한다.

Ghostty XDG 설정의 D2Coding을 유지한다. Mac의 `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`도 별도 확인한다. 조사 당시 해당 파일은 비어 있었다. 상위 경로의 기존 설정은 자동 삭제하지 않는다.

## 복구와 검증 경계

적용 직전 출력한 diff와 변경 대상의 권한/symlink/존재 여부를 개인 백업한다. 백업 경로·추가 설치 목록·복원 절차·실제 CLI/GUI/재실행 결과는 완료 후 여기 기록한다. API/service 로그인과 앱 권한은 사용자가 준비하며 설치 성공과 구분한다.

공식 근거: [mise bootstrap](https://mise.jdx.dev/bootstrap/packages/), [Homebrew와 mise 소유권 차이](https://mise.jdx.dev/bootstrap/packages/brew.html), [Kiro 설치](https://kiro.dev/docs/getting-started/installation/), [Grok 공식 CLI](https://docs.x.ai/build/overview), [Ghostty 설정 위치](https://ghostty.org/docs/config).
