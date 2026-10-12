# 기존 OS 설치 자동화 이행 — 2026-10-12

PR #1은 main의 `3d7115cd04b0dc8a01179dc47b959410f33d73bf`로 머지했다. 머지 트리는 앞서 hosted CI 12개를 통과한 트리와 같다. 기존 기기 선택을 유지하고 `automation.enabled=true`만 활성화한다. 실제 변경 전에 최신 diff와 대상별 개인 백업을 확인한다.

| OS | 현재 결과 | 보존과 변경 |
|---|---|---|
| Fedora | 앞선 적용·재실행 통과 | mise 34개, native provider·Conda·Bitwarden·externals=false 유지 |
| macOS ARM64 | 적용·재실행 통과 | mise 19개 + native CLI 5개, 앱·기기 선택·패키지 목록 유지 |
| Ubuntu | 적용·재실행 통과 | CLI 22개 유지, Pi 1.1.0의 설치 메타데이터만 수정, gawk 1개 추가 |
| Arch | 적용·재실행 통과 | CLI 22개, 관리 경로 1,945개·전체 패키지 목록 동일 |
| openSUSE | 실제 userland 적용·재실행 통과 | CLI 22개 유지, bzip2 1개와 설치기 전용 Python 3.12.15 추가; QGA·SELinux·fstab·resolver 링크 유지 |
| Windows | 적용·재실행 통과 | mise 16개, 관리 파일 22개, native provider·인증·PATH·실행 정책 유지; 프로필 ACL의 자동 상속 표시만 정규화 |

openSUSE는 기본 QGA/SELinux 정책을 유지하기 위해 VM 종료 상태에서 독립 마운트 공간과 실제 openSUSE userland를 사용했다. 이는 이번 변경의 GUI 재검증을 뜻하지 않는다. 각 기기의 `~/.local/state/dotfiles/init-backups/`, `backups/`, `review/<OS>/automation-migration-20261012-main/`에 복구 자료와 검증 기록을 개인 권한으로 보관한다. 서비스 인증과 GUI 권한은 변경하지 않았다. FreeBSD와 다른 학습용 VM은 대상에서 제외했다.

Ubuntu의 불필요한 sudo/APT 갱신, Windows의 재초기화 시 모듈 경로 충돌, 변경 없는 프로필 재쓰기를 막는 추가 개선은 PR #2에 준비했다. 로컬 계약 테스트 26개는 통과했지만 hosted CI는 계정 결제/사용 한도 문제로 작업 시작 전에 거절됐다. PR #2는 머지하거나 실제 OS에 배포하지 않았다. 기존 OS에는 앞서 검증한 main만 사용했다. Fedora 소스의 별도 미커밋 OpenCode 1.19.0 변경은 보존했다.

Windows에서는 초기화에만 PSModulePath를 자식 프로세스에 전달하지 않는 일회성 실행 환경을 사용했다. 일반 apply는 원래 PowerShell 7 환경에서 통과했다. 프로필의 owner·group·전체 접근 규칙과 상속 보호 상태는 같고 `DiscretionaryAclAutoInherited` 메타데이터 비트만 추가됐음을 확인했다. 원본 before.json과 실패 단계 기록을 남긴 채 이 한 건만 반영한 expected-after.json으로 나머지 모든 지문을 다시 검사했다. 기존 미커밋 OpenCode 1.19.0 변경도 유지됐다. 개인 성공 기록은 `~/.local/state/dotfiles/review/windows/automation-migration-20261012-main/result.json`이다.

각 OS에서 이후 유지보수는 다음 명령을 사용한다.

```sh
chezmoi diff --exclude=scripts
chezmoi apply
chezmoi verify --exclude=scripts
```

재실행은 선택된 도구의 누락 복구와 설정·CLI 실행 검증을 수행한다. 전체 업그레이드·공급자 이전·서비스 인증은 자동으로 수행하지 않는다. Ubuntu main의 반복 실행은 APT 갱신에 sudo가 필요할 수 있고, 이 불필요한 요청 제거는 CI 대기 중인 PR #2에 있다. PowerShell 7에서 Windows 재초기화 시의 호환성 개선도 같은 PR에 있다.

Windows 작업 파일 3개와 Mac의 일회성 /tmp 파일 2개를 제거했다. Mac의 짧은 이름이 해석되지 않아 동일한 기존 SSH 호스트 키를 엄격하게 검증한 mac.local로 연결했고, 앞선 성공 기록을 확인한 뒤 작업 파일만 정리했다. SSH 설정이나 known_hosts는 변경하지 않았다. 검증 VM은 모두 정상 종료 상태이며, Fedora의 38개 마운트 namespace에서 Crucial 작업 마운트가 0개임을 확인했다. 학습용 VM·FreeBSD·VM 정의·파티션·GRUB·보호 훅은 변경하지 않았다.
