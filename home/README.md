# chezmoi source

사용자 설정 원본·기기 데이터·템플릿과 고정 업스트림 선언을 둔다. docs/scripts/tests는 source 밖이다. 현재 Fedora 적용 구성과 Ubuntu 검토 구성이 있고, 기본 deployment.enabled=false라 모든 대상이 제외된다. 명시적으로 켜면 Fedora/Ubuntu를 지원한다. 실제 Ubuntu 사용자 홈 적용은 별도 단계다.

실제 홈에 연결하거나 적용하지 않았다. 임시 config/cache/state/destination을 지정한 검증에서만 설정을 생성했다. [Fedora 판단](../docs/fedora-review.md)을 참고한다. 이 README는 배포하지 않는다.
