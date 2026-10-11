# 기존 개인 Fedora의 설치 자동화 이행

새 Fedora portable full과 이미 설치된 개인 Fedora를 구분한다. 개인 프로필은 기존 common 13개·OpenCode 1개·개인 20개, 총 34개 mise 도구를 유지한다. Conda·Bitwarden agent·기존 AI/GUI 설치 출처·개인 completion·셸 선택과 externals=false도 유지한다. 다른 OS에 적용하지 않는다.

## 활성화와 보존 범위

`chezmoi init --apply`만 반복하면 기존 자동화 비활성 선택을 유지한다. 이행은 기존 기기 선택을 읽고 `automation.enabled=true`만 명시적으로 초기화 데이터에 추가한다. 초기화 전 chezmoi config와 원래 권한을 보존하고, run_before가 최신 설정 diff와 변경 대상 백업을 만든다. 외부 checkout을 다시 내려받거나 새 full 프로필로 바꾸지 않는다. 예전 config에 없던 managed_ai/desktop=false는 설치 출처 변경으로 판단하지 않는다. true로의 변경은 여전히 거부한다.

필요한 기존 OMZ·tmux·Conda와 native AI/GUI 실행 파일이 있는지 먼저 확인한다. 이 프로필은 이미 설치된 개인 환경용이며, 누락된 native AI·Conda·앱은 기존 공급자로 복구한 뒤 이행해야 한다. mise로 소유권을 가져오거나 Miniforge·Bitwarden GUI를 자동 재설치하지 않는다. Native AI·Ghostty·Orca·Conda/Mamba의 실행 경로·대상·SHA-256을 전후 비교한다.

자동화 활성화 후 일반 `chezmoi apply`는 선택된 mise 버전의 설치 상태와 실행 파일을 검사한다. 설치 이름과 실제 명령이 다른 Ansible/aws/az/bw/cf/mysql/tofu/rustc도 올바르게 확인한다. 손상된 선택 버전만 복구하며 정상 버전과 다른 버전을 일괄 재설치·업그레이드·정리하지 않는다.

Rust는 mise가 지정한 rustup toolchain을 확인한다. 단순히 ~/.cargo/bin이 mise installs 밖에 있다는 이유로 거부하지 않는다. kubectl 검증은 client-only이며 클러스터에 접속하지 않는다. Ansible·Azure·Bitwarden 버전 검사는 임시 앱 상태를 사용한다. 서비스 인증이나 실제 클러스터 작업의 성공은 설치 검증과 별개다.

## 검증

Foundation checks는 기존 다섯 OS의 설정/공급자 회귀, 기존 optional=false 선택의 재초기화, provider guard와 명령/상태 격리를 검사한다. 별도 Fedora personal migration hosted job은 일회성 일반 사용자에서 기존 profile과 shell checkouts를 준비하고, 34개 실제 mise CLI 설치·버전 확인·반복 apply·Ansible 실행 파일 삭제 후 복구를 검사한다. Native AI/Conda/GUI는 보존 동작용 fixture이며 실제 제품 실행 검증으로 해석하지 않는다.

실제 Fedora 적용 결과·diff·백업 위치는 적용 후 별도로 기록한다. 초기화 원본은 ~/.local/state/dotfiles/init-backups/, 설정 대상 백업과 전후 검증 결과는 ~/.local/state/dotfiles/backups/ 및 review/fedora/에 개인 권한으로 저장한다. 원래 config는 init-backups의 chezmoi.toml과 mode.txt로 복원하고, 설정 파일은 대상별 manifest에 따라 복구한다. 설치된 바이너리 제거는 설정 복원과 별개다.

공식 근거: [mise Rust/rustup](https://mise.jdx.dev/lang/rust.html), [Ansible local temp](https://docs.ansible.com/projects/ansible/latest/reference_appendices/config.html#default-local-tmp), [Bitwarden CLI 앱 상태](https://bitwarden.com/help/cli/), [Azure CLI 설정](https://learn.microsoft.com/en-us/cli/azure/azure-cli-configuration).
