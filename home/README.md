# chezmoi 소스 루트

이 디렉터리만 사용자 홈에 대응한다. `.chezmoiroot`는 저장소 루트에 있고 내용은 `home`이다. 초기화 템플릿·데이터·ignore는 이곳에 둔다.

현재 `.chezmoiignore`가 모든 배포 대상을 제외하므로 대상 파일 목록은 비어 있어야 한다. 원본 위치와 기기 데이터를 격리 환경에서 검증할 수 있으나 실제 홈 설정과 연결하지 않는다.

후속 단계에서 검토한 파일만 `dot_zshrc.tmpl`, `dot_gitconfig.tmpl`, 앱별 `dot_config/` 등에 추가하고 해당 배포 경계를 함께 갱신한다. `.gitkeep`, 문서용 README, 설치 결과를 사용자 설정으로 가져오지 않는다.
