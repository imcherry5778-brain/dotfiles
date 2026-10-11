# 플랫폼과 검증 수준

| 대상 | OS 판정 값 | 현재 검증 범위 |
|---|---|---|
| Fedora | fedora / linux | 실제 설정 분석, draft 반복 적용·부분 갱신·문법·격리된 OMZ 초기화; 실제 홈 미적용 |
| Ubuntu | ubuntu / linux | fixture, CI의 Linux 러너 기본 검사 |
| Arch | arch / linux | fixture만; pacman·데스크톱 미검증 |
| openSUSE Tumbleweed | opensuse-tumbleweed / linux | fixture만; Zypper·데스크톱 미검증 |
| macOS | macos / darwin | fixture와 CI의 기반 검사; 실제 기기 미검증 |
| Windows | windows / windows | fixture와 CI의 PowerShell 기반 검사; 실제 기기 미검증 |

CI 성공은 스크립트 구문·격리 렌더링·초기화·배포 경계·경로 처리를 확인한다. 로그인·SSH/GPG·클립보드·GUI·도구 설치·모든 배포판 호환성 완료를 의미하지 않는다.

현재 실사용 configuration source는 Fedora draft만 있다. 다른 OS의 기반 init/plan/check가 성공했다고 그 OS에 Fedora 설정을 배포하지 않는다. `.chezmoiignore`가 Fedora 외 대상 전체를 제외한다.

각 OS는 자기 사용자 홈에 독립 checkout을 둔다. 경로 예시는 Linux /home/<user>/projects/imcherry5778-brain/dotfiles, macOS /Users/<user>/projects/imcherry5778-brain/dotfiles, Windows의 실제 $HOME 아래 projects/imcherry5778-brain/dotfiles다.

FreeBSD는 이번 자동화 대상에서 제외한다. 기존 FreeBSD 설치·VM은 이 저장소 구축과 무관하게 유지한다. 파티션·GRUB·VM·디스크 공유 훅은 변경 범위에 포함하지 않는다.
