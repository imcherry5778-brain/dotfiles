# 기존 개인 Fedora의 설치 자동화 이행

새 Fedora portable full과 이미 설치된 개인 Fedora를 구분한다. 개인 프로필은 기존 common 13개·OpenCode 1개·개인 20개, 총 34개 mise 도구를 유지한다. Conda·Bitwarden agent·기존 AI/GUI 설치 출처·개인 completion·셸 선택과 externals=false도 유지한다. 다른 OS에 적용하지 않는다.

## 활성화와 보존 범위

`chezmoi init --apply`만 반복하면 기존 자동화 비활성 선택을 유지한다. 이행은 기존 기기 선택을 읽고 `automation.enabled=true`만 명시적으로 초기화 데이터에 추가한다. 초기화 전 chezmoi config와 원래 권한을 보존하고, run_before가 최신 설정 diff와 변경 대상 백업을 만든다. 외부 checkout을 다시 내려받거나 새 full 프로필로 바꾸지 않는다. 예전 config에 없던 managed_ai/desktop=false는 설치 출처 변경으로 판단하지 않는다. true로의 변경은 여전히 거부한다.

필요한 기존 OMZ·tmux·Conda와 native AI/GUI 실행 파일이 있는지 먼저 확인한다. 이 프로필은 이미 설치된 개인 환경용이며, 누락된 native AI·Conda·앱은 기존 공급자로 복구한 뒤 이행해야 한다. mise로 소유권을 가져오거나 Miniforge·Bitwarden GUI를 자동 재설치하지 않는다. Native AI·Ghostty·Orca·Conda/Mamba의 실행 경로·대상·SHA-256을 전후 비교한다.

자동화 활성화 후 일반 `chezmoi apply`는 선택된 mise 버전의 설치 상태와 실행 파일을 검사한다. 설치 이름과 실제 명령이 다른 Ansible/aws/az/bw/cf/mysql/tofu/rustc도 올바르게 확인한다. 손상된 선택 버전만 복구하며 정상 버전과 다른 버전을 일괄 재설치·업그레이드·정리하지 않는다.

Rust는 mise가 지정한 rustup toolchain을 확인한다. 단순히 ~/.cargo/bin이 mise installs 밖에 있다는 이유로 거부하지 않는다. kubectl 검증은 client-only이며 클러스터에 접속하지 않는다. Ansible·Azure·Bitwarden 버전 검사는 임시 앱 상태를 사용한다. 서비스 인증이나 실제 클러스터 작업의 성공은 설치 검증과 별개다.

## 검증

Foundation checks는 기존 다섯 OS의 설정/공급자 회귀, 기존 optional=false 선택의 재초기화, provider guard와 명령/상태 격리를 검사한다. 별도 Fedora personal migration hosted job은 일회성 일반 사용자에서 기존 profile과 shell checkouts를 준비하고, 34개 실제 mise CLI 설치·버전 확인·반복 apply·Ansible 실행 파일 삭제 후 복구를 검사한다. Native AI/Conda/GUI는 보존 동작용 fixture이며 실제 제품 실행 검증으로 해석하지 않는다.

초기화 원본은 ~/.local/state/dotfiles/init-backups/, 설정 대상 백업과 전후 검증 결과는 ~/.local/state/dotfiles/backups/ 및 review/fedora/에 개인 권한으로 저장한다. 원래 config는 init-backups의 chezmoi.toml과 mode.txt로 복원하고, 설정 파일은 대상별 manifest에 따라 복구한다. 설치된 바이너리 제거는 설정 복원과 별개다.

공식 근거: [mise Rust/rustup](https://mise.jdx.dev/lang/rust.html), [Ansible local temp](https://docs.ansible.com/projects/ansible/latest/reference_appendices/config.html#default-local-tmp), [Bitwarden CLI 앱 상태](https://bitwarden.com/help/cli/), [Azure CLI 설정](https://learn.microsoft.com/en-us/cli/azure/azure-cli-configuration).

## 2026-10-12 실제 Fedora 이행 결과

코드 `df96f19`의 [Foundation 3개 검사](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38178974998)와 [Installation 9개 검사](https://github.com/imcherry5778-brain/dotfiles/actions/runs/38178975008)가 모두 통과한 뒤 실제 개인 Fedora에 적용했다. 다른 개인 OS에는 적용하지 않았다.

적용 직전 설정 diff는 0바이트였고, 기존 config 선택을 보존하면서 automation.enabled=true를 활성화했다. 누락돼 있던 managed_ai/desktop=false와 빈 machine.mise_data_dir 기본값도 명시됐다. 선택된 34개 mise 도구와 설치기 Python 3.12.15는 이미 설치돼 있어 새 설치·재설치·업그레이드는 0개였다. RPM 21개 필수 패키지도 기존 설치를 그대로 사용했다.

기존 OpenCode 1.19.0 파일은 원하는 내용과 같지만 chezmoi의 이전 기록과 달라 첫 apply가 확인 프롬프트에서 멈췄다. 원문과 desired bytes가 같음을 다시 검사한 뒤 이 파일만 `apply --force --exclude=scripts PATH`로 기록을 동기화했다. 나머지 대상에는 force를 사용하지 않았다. 실행 래퍼의 비공개 로그용 umask가 상속돼 일시적으로 좁아진 408개 파일·7개 디렉터리의 권한은 변경 전 지문과 설정 모델로 원상복구했다. 사용자 파일 내용에는 변화가 없었으며 이후 원래 umask로 정상 apply를 완료했다. 저장소 설치 모듈에 이 umask 래퍼를 추가하지 않았다.

일반 `chezmoi apply`를 한 번 더 실행해 재실행을 확인했다. 최종 verify와 scripts 제외 diff가 통과했다. 적용 전후 477개 관리 파일의 내용·권한, 34개 도구의 버전·실행 경로·SHA-256·mtime, 11개 native provider, 인증/Git/SSH 7개 파일의 지문과 RPM 전체 목록이 동일했다. 저장소의 별도 미커밋 OpenCode 1.19.0 변경도 그대로다. Native 앱의 GUI나 서비스 로그인 성공을 이번 검사의 결과로 주장하지 않는다.

이 기기의 비공개 기록은 `~/.local/state/dotfiles/review/fedora/automation-migration-20261012/`에 있다. 원래 초기화 config는 `~/.local/state/dotfiles/init-backups/init-ijyVUSaX/`에, 대상별 복구본·반복 적용 복구본의 경로는 비공개 application.json에 기록했다. 인증 원문이나 백업 파일을 Git에 올리지 않았다.

이후 일반 유지보수는 다음과 같다. apply는 설정 적용과 선택된 mise 도구의 누락 복구·실행 검증을 수행한다. Native AI·Conda·앱이 없어지면 기존 공급자로 복구하도록 중단한다. 전체 업그레이드나 공급자 이전은 자동으로 수행하지 않는다.

```sh
chezmoi diff --exclude=scripts
chezmoi apply
chezmoi verify --exclude=scripts
```
