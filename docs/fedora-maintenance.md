# Fedora 업데이트 점검과 실행 환경 복구

2026-10-26 사용자 승인에 따라 로컬 `~/scripts/sys-update`를 보완하고 NVIDIA CDI와 DeepFilterNet을 복구했다. 도구 설치 주체 이전은 [패키지 관리 기록](fedora-package-migration.md)에 있다. 이 문서는 적용 기록이며 로컬 스크립트·시스템 설정의 별도 배포 선언을 추가하지 않는다.

## sys-update 실행과 보고

- `sys-update --check`는 sudo 인증·업데이트·삭제·서비스 변경 없이 후보와 설치 상태를 조회한다. 메타데이터 캐시와 자체 로그·보고서는 기록한다. 결과는 `~/.local/state/sys-update/checks/latest.md`에 저장한다.
- 일반 `sys-update`는 기존 업데이트·정리 흐름을 수행하고 단계별 출력과 종료 코드를 보관한다. 실패가 하나라도 있으면 전체 종료 코드도 0이 아니며, 중간 중단·실패에도 이번 실행의 보고서와 최신 링크를 작성한다. 정상 업데이트 보고서는 기존 `~/.local/state/sys-update/latest.md` 경로를 유지한다.
- root와 home은 각각 pre/post 스냅샷을 생성한다. /boot·펌웨어는 포함하지 않으며 root undochange만으로 전체 업데이트를 복구할 수 있다고 안내하지 않는다.
- mise upgrade는 `--no-prune`로 이전 버전을 보존한다. 검증 없는 자동 mise prune와 cache prune를 제거했다. 고정 범위 밖 후보는 별도로 조회하고 설정을 자동 bump하지 않는다.
- npm·CDI·Ollama·릴리스 조회의 오류를 완료 또는 최신으로 표시하지 않는다. 설치 버전과 원격 버전을 숫자로 비교해 같은 버전·상위 후보·하위 릴리스를 구분한다. Ollama 설치기는 다운로드 성공을 먼저 확인하고, 고정한 후보 버전으로 실행한 뒤 설치 버전을 재확인한다.
- DNF와 Rustup 조회의 코드 100은 업데이트 후보로 처리한다. npm의 후보 코드 1은 정상 후보 JSON인지 확인하고, 오류 JSON은 실패로 남긴다. 재부팅 진단은 NO·YES·UNKNOWN을 구분한다.
- DNF 이력은 upgrade 한 건만 뽑지 않고 시작 전 ID 집합과 비교해 실행 중 발생한 트랜잭션을 보고한다. 잘못된 `coredumpctl vacuum`을 제거하고 coredump 경로에 한정한 systemd-tmpfiles 보관 정책을 사용한다.
- Android SDK·JetBrains·Conda·uv Python·venv·사용자 pip·cargo·GNOME 확장·Bottles·서비스 이미지·virtio-win·펌웨어의 조회 또는 수동 관리 안내를 추가했다. 커널 모듈·CDI 참조·가상환경 Python 연결도 점검한다.

`~/scripts/tests/test_sys_update.py`는 함수 오류와 격리된 전체 실행 흐름을 검사한다. 명령 대역을 사용해 실제 패키지 업데이트 없이, 후보·조회 오류 구분, 실패 보고·최신 링크, 중단 후 root/home post 스냅샷, DNF 전체 이력, 점검 모드의 무변경·무sudo, 자동 prune 부재를 확인한다. 14개 검사와 Bash 구문·ShellCheck를 통과했다. 실제 PC의 최종 `--check`도 종료 0, 실패·판정 불가 0개를 확인했다. 전체 시스템 업데이트 자체는 이번 작업에서 실행하지 않았다.

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
