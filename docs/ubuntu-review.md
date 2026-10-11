# Ubuntu CLI 구성과 적용 준비

2026-10-11에 설치된 Ubuntu 26.04.1을 읽기 전용으로 조사했다. 사용자 홈은 Bash 기본값과 GNOME 설정이며 선정 도구 중 APT jq만 있었다. Zsh·tmux·Git·mise·chezmoi와 나머지 CLI는 없었다. 실제 Ubuntu 적용은 아직 진행하지 않았다.

## 유지와 변경

- .bashrc 기존 prompt·history·alias·native completion·사용자 설정을 유지하고 공통 CLI 모듈 로드만 추가한다. .profile/.bash_logout은 관리하지 않는다.
- 공통 CLI 13개 + OpenCode + Node를 Fedora와 같은 검토 버전으로 고정한다. APT jq와 system Python은 제거·교체하지 않는다.
- Zsh/OMZ·tmux·LazyVim·Git/gh 공통 설정과 AI 선호를 새로 준비한다. Git identity·서명·AI/gh 인증은 복사하지 않는다.
- Fedora 추가 20개·RPM completion·Conda·Bitwarden 경로는 선택하지 않는다. delta는 설치하되 Git pager 기능은 끈다.
- Ubuntu chezmoi-only umask 077로 기존 사용자 전용 디렉터리 700을 보존한다. .bashrc는 644→600이다.

AI 세 도구의 선호 설정과 해당 실행 파일 설치는 별개다. 이 프로필의 AI 설치는 OpenCode만 포함한다. 나머지 7개 AI CLI·Ghostty·앱 로그인은 추후 단계다.

## 검증과 적용 경계

격리 source 검사와 hosted Ubuntu 26.04 설치 테스트를 구현했다. hosted 설치 결과는 해당 commit의 Actions로 확인한다. CI는 도구 다운로드·버전/경로·PTY Zsh·Bash 공급자 보존·tmux 플러그인·Neovim Lua 구문·반복 설치를 확인하며, 사용자 PC나 Self-hosted runner를 사용하지 않는다.

실제 적용 전에는 최신 Ubuntu diff와 변경 대상 백업을 다시 확보한다. OS 패키지 준비 → 실제 프로필 초기화 → mise 도구 설치 → external/설정 적용 → Zsh 기본 셸 전환 → 실제 데스크톱/클립보드/LazyVim 실행 순서로 진행한다. CI 성공이 사용자 기기 적용·GUI·플러그인·인증 성공을 뜻하지 않는다.

[설치 계약](install.md), [설정 차이](configuration.md), [검증 범위](../tests/README.md)를 함께 확인한다.

Ubuntu 컨테이너는 Canonical의 [공식 Ubuntu 이미지](https://hub.docker.com/_/ubuntu)의 26.04 태그를 사용한다. Bash 변경은 [chezmoi modify-template](https://www.chezmoi.io/user-guide/manage-different-types-of-file/)로 기존 내용을 보존한다. [chezmoi umask 정책](https://www.chezmoi.io/user-guide/frequently-asked-questions/troubleshooting/)은 운영체제 umask와 분리한다.
