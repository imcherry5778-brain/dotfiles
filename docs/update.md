# 업데이트 계약

현재 업데이트 작업은 구현하지 않았다. 저장소 기반 구성 중 설치된 CLI나 시스템 패키지를 업그레이드하지 않는다.

설정·버전 변경은 소스 갱신 → push/PR → 해당 Foundation/Installation checks → 실제 기기 diff·백업 검토 → 필요한 도구 설치 → 전체 설정 적용 → 실제 기기 확인 순서로 진행한다. Actions는 GitHub의 일회성 환경에만 적용하며 사용자 기기의 갱신을 자동 실행하지 않는다. 현재 개인 Fedora 이전은 common baseline installer와 분리해 준비한다. 버전 변경은 설치/설정 주체 이전과 분리해 후보 버전·lockfile·검증 기록을 함께 수정한다.

mise 관리 도구, 공식 설치 예외, OS 패키지는 각각 한 주체에서 갱신한다. 기존 Fedora sys-update 연동도 이 주체를 확정한 뒤 별도 변경으로 진행한다. 새 버전 검증 전에 이전 버전 prune를 자동 실행하지 않는다.
