# Fedora 업데이트 점검과 실행 환경 복구

2026-10-26 사용자 승인에 따라 로컬 `~/scripts/sys-update`를 보완하고 NVIDIA CDI와 DeepFilterNet을 복구했다. 도구 설치 주체 이전은 [패키지 관리 기록](fedora-package-migration.md)에 있다. 이 문서는 적용 기록이며 로컬 스크립트·시스템 설정의 별도 배포 선언을 추가하지 않는다.

## sys-update 실행과 보고

2026-10-27 추가 점검에서 Orca 1.4.241 RPM의 `chrome-sandbox` build-id 링크가 Kiro Crew 0.10.0의 링크와 충돌하는 것을 재현했다. 공통 RPM 처리기는 실제 트랜잭션 문제를 구조화해 ai-cli와 sys-update 보고서까지 전달한다. 일반 공급자 출력·인증 정보는 여전히 전달하지 않는다.

단일 관리 앱의 갱신에서 모든 충돌이 `/usr/lib/.build-id` 아래의 RPM artifact 링크이고, 기존 소유 앱과 링크·공식 RPM의 artifact 목록을 검증한 경우에만 RPM의 `--excludeartifacts`를 사용한다. artifact 디렉터리와 같은 build-id의 `.1`·`.2` 링크도 판별한다. DNF가 받은 원본의 공식 체크섬·내부 digest·이름·버전·아키텍처 검증, 별도의 RPM 설치 전 검사, 설치 직전 재검증과 설치 후 파일·버전 검증은 유지한다. 다른 파일 충돌·다른 패키지 변경은 차단하며 `--replacefiles`·`--force`는 사용하지 않는다. 이 복구 경로의 실제 설치는 RPM DB와 ai-cli 실행 기록에 남고 DNF 트랜잭션 이력에는 포함되지 않으며, 해당 차이를 결과 메시지에 표시한다.

확인만 하는 AI 제품은 갱신 건수에 포함하지 않도록 보완했고, 추가 후보·실패를 출력한 뒤 “추가 후보 없음”을 덧붙이는 요약 오류도 수정했다. 해당 보완의 백업·테스트·실제 갱신 결과는 `~/.local/state/sys-update-repair/20261027T021051-orca-audit/`에 있다. Orca만 1.4.224에서 1.4.241로 갱신했으며, 실행 중인 앱은 종료하지 않았다. 새 Desktop 실행은 사용자가 앱을 다시 열 때 확인해야 한다.

설치 메타데이터에 버전이 없는 Antigravity CLI·Kiro CLI·Grok은 임시 HOME에서 실행 버전을 확인해 최신이면 재설치를 생략한다. Kiro의 필수 보조 실행 파일 누락은 복구 대상으로 유지하고, 더 높은 설치 버전은 다운그레이드하지 않는다. 최종 전체 조회는 종료 0·실패 0·추가 후보 0이며, 기존 정책에 따른 보류 7개·수동 관리 4개와 비활성 Python shim 안내 1건은 별도로 남는다. sys-update 검사 103개와 별도 root 격리 RPM 시험 1개, 최신 ai-cli 검사 556개가 통과했다.

- `sys-update --check`는 sudo 인증·업데이트·삭제·서비스 변경 없이 후보와 설치 상태를 조회한다. 메타데이터 캐시와 자체 로그·보고서는 기록한다. 결과는 `~/.local/state/sys-update/checks/latest.md`에 저장한다.
- 일반 `sys-update`는 기존 업데이트·정리 흐름을 수행하고 단계별 출력과 종료 코드를 보관한다. 실패가 하나라도 있으면 전체 종료 코드도 0이 아니며, 중간 중단·실패에도 이번 실행의 보고서와 최신 링크를 작성한다. 정상 업데이트 보고서는 기존 `~/.local/state/sys-update/latest.md` 경로를 유지한다.
- root와 home은 각각 pre/post 스냅샷을 생성한다. /boot·펌웨어는 포함하지 않으며 root undochange만으로 전체 업데이트를 복구할 수 있다고 안내하지 않는다.
- mise upgrade는 `--no-prune`로 이전 버전을 보존한다. 검증 없는 자동 mise prune와 cache prune를 제거했다. 기본 실행은 고정 범위 밖 후보만 조회한다. 명시적으로 선택한 `--extras=mise`에서는 버전 설정과 확인된 chezmoi 원본도 갱신한다.
- npm·CDI·Ollama·릴리스 조회의 오류를 완료 또는 최신으로 표시하지 않는다. 설치 버전과 원격 버전을 숫자로 비교해 같은 버전·상위 후보·하위 릴리스를 구분한다. Ollama 설치기는 다운로드 성공을 먼저 확인하고, 고정한 후보 버전으로 실행한 뒤 설치 버전을 재확인한다.
- DNF와 Rustup 조회의 코드 100은 업데이트 후보로 처리한다. npm의 후보 코드 1은 정상 후보 JSON인지 확인하고, 오류 JSON은 실패로 남긴다. 재부팅 진단은 NO·YES·UNKNOWN을 구분한다.
- DNF 이력은 upgrade 한 건만 뽑지 않고 시작 전 ID 집합과 비교해 실행 중 발생한 트랜잭션을 보고한다. 잘못된 `coredumpctl vacuum`을 제거하고 coredump 경로에 한정한 systemd-tmpfiles 보관 정책을 사용한다.
- Android SDK·JetBrains·Conda·uv Python·venv·사용자 pip·cargo·GNOME 확장·Bottles·서비스 이미지·virtio-win·펌웨어의 조회 또는 수동 관리 안내를 추가했다. 커널 모듈·CDI 참조·가상환경 Python 연결도 점검한다.

`~/scripts/tests/test_sys_update.py`는 함수 오류와 격리된 전체 실행 흐름을 검사한다. 명령 대역을 사용해 실제 패키지 업데이트 없이, 후보·조회 오류 구분, 실패 보고·최신 링크, 중단 후 root/home post 스냅샷, DNF 전체 이력, 점검 모드의 무변경·무sudo, 자동 prune 부재를 확인한다. 설치된 akmod의 실행 커널 모듈이 없을 때도 실패로 보고한다. 15개 검사와 Bash 구문·ShellCheck를 통과했다. 실제 PC의 `--check`도 종료 0, 실패·판정 불가 0개를 확인했고 최종 커널 점검 변경은 실제 모듈 조회로 재검증했다. 전체 시스템 업데이트 자체는 이번 작업에서 실행하지 않았다.

## 선택 추가 업데이트 (`--extras`)

```sh
sys-update --extras                    # apps: 기존 Ollama와 지원 앱
sys-update --extras=apps,ai,uv         # 그룹 선택; 기본 업데이트에 추가
sys-update --extras=mise               # 전역 mise의 버전 고정도 갱신
sys-update --check --extras=all        # 모든 그룹 조회만
sys-update --extras=all                # 모든 그룹 실행; 펌웨어 설치 포함
sys-update --extras=all --force        # 실행 중 검사만 무시
```

그룹은 `apps`, `ai`, `uv`, `mise`, `distrobox`, `firmware`다. 미설치 제품은 새로 설치하지 않는다. 같은 제품은 한 관리 주체에서만 처리한다. Aider는 uv 그룹을 함께 선택하면 uv가 담당하고, OpenCode CLI는 ai 그룹을 함께 선택하면 ai-cli가 담당한다. 기본 DNF 저장소 제품은 추가 그룹에서 중복 갱신하지 않는다.

- `apps`: Ollama 공식 설치기, OpenWhispr·Docker Desktop·virtio-win의 공식 RPM, 기존 ai-cli를 통한 Kiro Crew·OpenCode Desktop·Orca를 갱신한다. RStudio는 내보내기가 가리키는 Distrobox 안에서 공식 Desktop DEB로 갱신한다.
- `ai`: 기존 ai-cli의 설치 주체·검증을 유지해 제품별로 갱신한다. 실행 중 검사만 무시하는 업데이트 전용 `--allow-running`을 sys-update의 `--force`와 연결했다. 다른 동작의 실행 중 검사와 경로·서명·설정 검증은 유지한다.
- `uv`: 기존 Python 실행 파일·extras·추가 요구사항을 보존한다. 이전용 정확한 버전 제약은 새 버전으로 갱신하고, 앱이 최신이면 기존 제약 내 의존성을 갱신한다. 다른 공급자나 복잡한 정책은 보류한다.
- `mise`: 전역 설정에 있는 설치된 도구의 새 정식 버전을 설치한 뒤 해당 버전 항목만 실제 설정·확인된 chezmoi 원본에 반영한다. 주 버전 상승도 가능하며 Java 배포판/주 버전과 명시적 특수 채널은 보존한다. 이전 설치본은 삭제하지 않는다. 백업은 `~/.local/state/sys-update/extras-backups/`에 남긴다. 프로젝트 설정·사용자 변경을 덮어쓰거나 커밋·푸시하지 않는다.
- `distrobox`: 컨테이너별 OS 패키지 갱신이다. 정지 컨테이너를 시작한 경우 작업 후 원래 상태로 돌리되 새 세션·프로세스가 있으면 종료를 보류한다. 이미지 재생성이나 서비스 컨테이너 갱신은 하지 않는다.
- `firmware`: 공식 fwupd 메타데이터를 갱신한 뒤 발견한 장치 ID로 업데이트한다. dbx ID·버전을 하드코딩하지 않는다. 선택 옵션을 설치 요청으로 취급하고 fwupd의 필수 검사·확인을 유지한다. 자동 재부팅과 fwupd `--force`는 사용하지 않는다. 설치가 예약됐다면 재부팅 후 확인이 필요한 보류 상태로 기록한다.

독립 RPM은 `~/scripts/lib/sys_update_extras.py`가 libdnf5 URL API로 처리한다. DNF가 받은 같은 파일의 공식 체크섬/필요한 서명, 내부 digest, 이름·버전·아키텍처와 트랜잭션을 설치 전에 검증한다. 별도 curl 다운로드 뒤 로컬 파일을 다시 DNF에 넘기지 않는다. 서명 없는 공급자는 검토된 공식 체크섬이 필수이며, 잘못된/신뢰되지 않은 서명을 허용하지 않는다. 관련 없는 제거·대체와 다운그레이드는 차단한다. virtio-win은 호스트의 배포 파일만 바꾸며 Windows 게스트에 드라이버를 설치하지 않는다.

RealVNC Classic Viewer 7·Cisco Packet Tracer·호스트 Burp Suite는 이번 범위에서 수동 안내를 유지한다. Viewer 7을 새 Viewer 8로 자동 전환하지 않는다. RStudio·Packet Tracer의 Distrobox 위치와 Burp의 호스트 위치를 출력한다. `--check`에서는 정지 컨테이너를 시작하지 않아 내부 패키지 후보가 미확인일 수 있다.

결과는 갱신됨·최신·후보·보류·수동 필요·미설치·실패로 구분한다. 정상 완료는 0, 실패는 1, 실패 없이 요청 작업이 보류되면 2다. 조회에서 예상된 미확인/정지 상태와 예정된 수동 안내만으로는 실패하지 않는다. 최종 실행 결과는 수동 안내 아래에 둔다.

구현 전 파일과 검증 로그는 `~/.local/state/sys-update-repair/20261026-extras-implementation/`에 보관했다. 실제 앱·펌웨어 업데이트 대신 격리된 명령 대역 테스트, 임시 RPM을 실제 libdnf5로 해석하는 검사, 호스트의 `--check --extras=all`을 사용했다. 추가 테스트 58개와 ai-cli 회귀 테스트 556개, Bash 구문·ShellCheck가 통과했다. 최종 실제 조회는 종료 0·실패 0이며 기존 Python shim 경고 1건이 남았다. 실제 설정·RPM 목록·컨테이너 상태가 조회 전후 동일함을 확인했다.

## 첫 extras 실제 실행 후 보완

2026-10-26 첫 전체 실행 뒤 발견한 문제를 다음과 같이 보완했다. 앱·펌웨어 업데이트는 다시 실행하지 않았다.

- **DNF 권한**: 보고서용 `umask 077`이 libdnf5 트랜잭션에 상속돼 시스템 상태 TOML 6개가 `600`으로 저장됐다. 업데이트 전 root 스냅샷 24의 `644`와 비교하고, 현재 내용의 해시·TOML 형식을 확인한 뒤 권한만 복원했다. 앞으로 root RPM 처리에만 `umask 022`를 적용하고 성공·실패 모두 호출자의 umask를 복원한다. 보고서·하위 명령 로그는 비공개로 유지한다.
- **Distrobox 종료 판단**: 이 호스트의 컨테이너는 `pid=host`이므로 `podman top`으로 호스트 전체 프로세스를 비교하면 오탐한다. 컨테이너 init의 완전한 libpod cgroup 경로와 하위 cgroup만 검사한다. 활성 exec·사용자 작업·미확인 작업이 있으면 종료를 보류하고, 정지 직전 컨테이너 ID/PID와 작업을 다시 확인한다. init의 idle sleep과 root 시스템 DBus/GPG 서비스는 사용자 작업으로 오인하지 않는다. 오탐으로 남았던 5개 컨테이너는 내부 사용자 작업이 없음을 확인해 원래 정지 상태로 복원했다. OS 갱신과 종료 복원은 출력에서 구분한다.
- **사전 검사·터미널**: 기본 업데이트·관리자 인증 전에 추가 관리 대상의 실행 상태를 표시한다. 계속·종료 후 재검사·취소를 선택하며 실제 설치 직전 검사도 유지한다. `--force`는 다른 검증을 생략하지 않는다. 비대화형 실행은 안내 후 계속하되 실행 중인 대상은 설치 직전에 보류한다. `/dev/tty`를 읽기·쓰기 별도 스트림으로 열어 비탐색 터미널의 `r+` 오류를 없앴다. 실제 PTY 테스트로 검증했다.
- **진행·로그**: 장시간 명령은 시작과 15초 간격 경과 시간을 표시한다. 하위 명령 원문은 비공개 전체 로그에 보관하며 JSON 응답에는 진행 문구를 섞지 않는다.
- **virtio-win**: 공식 RPM 저장소 설정은 `gpgcheck=0`이고 직접 다운로드의 `CHECKSUM`은 MD5여서 기존 서명 필수 조건으로는 설치할 수 없었다. 검증을 생략하지 않고 HTTPS의 공식 `repomd.xml` → SHA256 검증된 primary 메타데이터 → 같은 버전·release·아키텍처 RPM의 SHA256·크기를 사용한다. MD5 대체, 메타데이터/패키지 버전 불일치와 잘못된 서명은 허용하지 않는다. 시스템 저장소를 새로 추가하거나 저장소 GPG 검증을 전역으로 끄지 않는다. [공식 저장소 설정](https://fedorapeople.org/groups/virt/virtio-win/virtio-win.repo), [공식 메타데이터](https://fedorapeople.org/groups/virt/virtio-win/repo/stable/repodata/repomd.xml).

백업과 검사 근거는 `~/.local/state/sys-update-repair/20261026T181814-hardening/`에 있다. 회귀 검사 74개와 ai-cli 검사 556개, ShellCheck·구문 검사가 통과했다. 실제 virtio-win RPM을 임시 다운로드해 SHA256·내부 digest·패키지 정보를 검증하고 삭제했으며 설치하지 않았다. 최종 `--check --extras=all`은 종료 0·실패 0, 재부팅 필요 없음이다. 기존 Python shim 경고 1건과 의도된 수동/보류 항목은 남는다. 설정·설치 RPM 목록은 보완 전후 동일하다. 기존 실제 업데이트 보고서는 당시 결과로 보존하며, 보완 후 조회 결과는 `~/.local/state/sys-update/checks/latest.md`에 기록한다.

## 조회 결과의 앱 종료 안내

```sh
sys-update --check --extras=all   # 종료가 필요한 앱·PID·이유와 명령 안내
sys-update --close-apps           # 작업 저장 후, 대상 앱 밖의 터미널에서 종료 요청
sys-update --extras=all           # 업데이트는 별도 실행
```

`--close-apps --check`는 저장된 종료 목록만 미리 보며 신호를 보내지 않는다. `--close-apps`는 `--extras`·`--force`와 함께 사용하지 않는다. 관리자 인증·패키지 갱신·펌웨어 적용·스냅샷 생성 경로로 들어가지 않는 별도 모드다.

종료 목록은 선택한 extras의 실제 갱신 후보와 실행 중인 프로세스를 교차 확인한다. 최신 앱은 별도 갱신을 위한 종료 대상으로 선정하지 않는다. uv는 앱 버전이 같아도 선택한 의존성 갱신 때문에 종료가 필요할 수 있으며 이유를 구분해 표시한다. 설치 버전 미확인 대상과 다른 사용자/시스템 서비스는 자동 종료에서 제외하고 별도 확인을 안내한다. 기본 DNF·Flatpak 전체 앱에 대한 종료 목록은 아니다.

`~/scripts/lib/sys_update_close.py`는 실행 파일 또는 실제 인터프리터 진입 스크립트의 소유 경로와 ai-cli의 공유 frontend 판정을 재사용한다. 일반 파일 인자나 이름 부분 문자열로 프로세스를 선택하지 않는다. 앱의 자식 프로세스·내장 터미널 세션이 함께 종료될 수 있으므로 작업을 먼저 저장한다. 현재 명령/터미널의 조상 앱이 대상이면 아무 프로세스에도 신호를 보내지 않고 외부 터미널 실행을 안내한다.

확인된 UID·부팅 ID·PID·시작 시각·실행 파일 경로/장치/inode는 `~/.local/state/sys-update/close-plans/`에 비공개로 저장한다. 조회 목록은 1시간 유효하고, 종료 직전에 pidfd와 신원을 재검증한다. 종료된 PID는 건너뛰며 다른 프로세스로 바뀐 PID와 새로 실행/재시작한 앱에는 신호를 보내지 않는다. SIGTERM만 요청하고 10초 후에도 실행 중이면 보류한다. SIGKILL로 자동 확대하지 않는다. 다른 sys-update가 실행 중이면 종료 모드도 실행 잠금에 의해 차단된다.

새 종료 대상 산정이 실패하면 예전 목록을 그대로 실행하지 못하도록 무효화한다. 종료 결과는 `close-plans/last-close.json`에 기록한다. 재조회 없이 최신 목록만 사용하는 기본 명령으로 제공하며 사용자가 PID 목록을 직접 복사해 kill할 필요가 없다. 이 기능을 구현하는 동안 실제 사용자 앱은 종료하지 않았고, 종료 신호 검증에는 격리된 임시 프로세스만 사용했다.

백업·실제 조회·종료 미리보기 검증 로그는 `~/.local/state/sys-update-repair/20261026T190805-close-apps/`에 있다. 회귀 검사 94개와 ai-cli 검사 556개, ShellCheck·구문 검사를 통과했다. 실제 `--check --extras=all`과 `--close-apps --check`도 종료 0이며 설정·RPM 목록·컨테이너 상태가 유지됐다. 실제 사용자 앱 종료와 업데이트는 실행하지 않았다.

## NVIDIA CDI

이전 `/etc/cdi/nvidia.yaml`은 없어진 615.71.09 드라이버 파일을 참조했다. 공식 `nvidia-cdi-refresh.path`와 service를 활성화해 `/run/cdi/nvidia.yaml`을 현재 615.78.08로 생성하고, 참조 파일 존재 여부를 검증한 뒤 이전 정의를 백업·제거했다. `/etc`와 `/run`의 중복 장치 정의를 남기지 않았다.

기존 로컬 Ubuntu 컨테이너 이미지를 사용하는 일회성 Podman 컨테이너에서 `nvidia.com/gpu=all` CDI 장치를 요청해 `nvidia-smi`가 드라이버 615.78.08을 출력하는 것을 확인했다. 기존 서비스 컨테이너나 VM을 재시작하지 않았다.

카메라 upstream 확인 unit은 설치된 ipu-bridge-fix 1.4와 다른 1.0 디렉터리만 검사하고 있었다. 조건을 `ConditionPathExistsGlob=/usr/src/ipu-bridge-fix-*/dkms.conf`로 수정해 버전 변경을 수용하고, systemd 조건 검사를 통과했다. DKMS를 자동 제거하는 본문은 이번 작업에서 실행하지 않았다.

## DeepFilterNet

기존 가상환경의 NumPy·Torch·torchaudio·DeepFilterNet 패키지는 유지했다. 누락된 CPython 3.11.15를 `uv python install --no-bin 3.11.15`로 설치하고, `~/.venvs/deepfilternet/bin/python` 및 pyvenv.cfg의 기반 경로를 uv 관리 Python으로 복구했다. mise의 이전 버전 정리에 의존하지 않으며 전역 Python 선택을 바꾸지 않았다.

`deepFilter --help` 실행뿐 아니라, 임시 1초 MKV 영상에 실제 `deepfilter-video`를 적용했다. 기존 DeepFilterNet3 모델을 로드해 CPU에서 오디오를 처리하고, 원본 FFV1 영상과 48 kHz FLAC 오디오를 결합한 출력까지 ffprobe로 확인했다. 임시 영상은 검사 후 정리했다. 기존 torchaudio의 import 경고는 남지만 명령은 종료 코드 0으로 완료됐다.

## 백업과 배포 경계

이번 복구의 백업과 실제 로컬 검사 근거는 `~/.local/state/sys-update-repair/20261026T060358+0900`에 있다. 이전 sys-update·CDI·카메라 unit·venv Python 링크와 pyvenv.cfg를 대상별로 보관했다. 사용자 인증 정보·모델·환경 전체를 저장소에 복사하지 않았다.

원격 main의 선행 변경은 보존하며 이번 패키지 소유권 선언·검증기·문서만 별도 커밋한다. 사용자가 원래 수정해 둔 OpenCode 버전 변경은 이번 커밋에 포함하지 않는다. 다른 OS의 실제 설정을 재적용하지 않는다.


## GitHub Copilot CLI·app 통합 (2026-10-27)

GitHub 공식 `github/copilot-cli` standalone 릴리스와 `github/app` RPM을 사용한다. 관리 ID는 `copilot`, `copilot-desktop`, 묶음은 `--family copilot`이다. `ai-cli` 1.7.0이 공식 릴리스 메타데이터·SHA256·설치 후 버전을 검증하고, `sys-update --extras=ai`는 이 구현에 위임한다. `--extras=apps`에는 데스크톱만 포함되며 두 그룹을 함께 지정해도 중복 실행하지 않는다.

CLI는 `~/.local/share/copilot-cli/releases/<version>/copilot`에 원본 공식 바이너리를 보관하고 `current`로 선택한다. `~/.local/bin/copilot`은 `--no-auto-update`를 추가하는 관리용 실행기다. 자체 갱신과 관리자의 파일 검증이 충돌하지 않도록 갱신은 아래 명령으로 수행한다. npm·mise 소유권을 중복 추가하지 않았다. VS Code 소유 `/usr/bin/copilot` shim은 보존하며, shim만 있을 때는 실제 CLI 설치로 판정하지 않는다.

```sh
ai-cli update --family copilot --check
ai-cli update --family copilot --execute
sys-update --extras=ai
```

공유 인증·세션 경로 `~/.copilot`은 설치 파일과 구분한다. uninstall은 관리하는 실행 파일·RPM만 제거하며, Copilot reset/history/purge는 공유 상태를 잘못 지우지 않도록 미지원으로 표시한다. 이번 설치에서는 사용자 인증·세션을 읽거나 삭제하지 않았다.

실제 CLI 1.0.103 실행, 데스크톱 RPM 1.1.32 설치와 무결성, 로그인 화면 표시를 확인했다. 로그인과 모델 요청은 사용자 단계로 남긴다. 회귀 검사와 실제 조회 근거, 변경 전 백업은 `~/.local/state/copilot-integration/20261027T025515/`에 보관한다.

이후 dotfiles에도 [Copilot CLI의 OS별 설치 선언](ai.md#copilot-cli-설치-선언)을 추가했다. 현재 Fedora의 기존 설치 주체와 관리 실행기는 보존한다. 이 추가는 CLI bootstrap만 다루며 데스크톱·공유 인증/설정·로컬 ai-cli/sys-update 구현의 배포는 포함하지 않는다.
