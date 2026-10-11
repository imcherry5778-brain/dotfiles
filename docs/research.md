# 구조를 정한 근거

확인일: 2026-10-11. 공식 문서·도구 도움말·공개 저장소의 구조를 확인했다. 단일한 dotfiles 폴더 표준이나 전체 사용자 사용 비율을 주장하지 않는다.

## 공식 기능

- [chezmoi 소스 루트](https://www.chezmoi.io/reference/special-files/chezmoiroot/): home 하위 디렉터리와 관련 특수 파일 위치.
- [초기화 템플릿](https://www.chezmoi.io/reference/special-files/chezmoi-format-tmpl/): 기기 config 생성.
- [static 데이터](https://www.chezmoi.io/reference/special-files/chezmoidata-format/): 공통 기본값과 동적 데이터의 구분.
- [sourceDir](https://www.chezmoi.io/reference/configuration-file/variables/#sourcedir): 사용자 지정 checkout 위치.
- [템플릿 변수](https://www.chezmoi.io/reference/templates/variables/): sourceDir와 workingTree의 구분. .chezmoiroot 적용 후 실제 렌더링 결과도 확인했다.
- [소스 파일 속성](https://www.chezmoi.io/reference/source-state-attributes/): dot_, .tmpl, modify_의 의미.
- [Windows](https://www.chezmoi.io/user-guide/machines/windows/): Windows 배포와 링크 관련 차이.
- [chezmoi init](https://www.chezmoi.io/reference/commands/init/): init 자체의 상태 변경과 --apply 구분.
- [mise 환경](https://mise.jdx.dev/configuration/environments.html): config.<환경>.toml과 명시적 선택.
- [mise 작업](https://mise.jdx.dev/tasks/task-configuration.html): 루트 작업 선언과 run_windows.
- [GitHub 액션 보안](https://docs.github.com/en/actions/reference/security/secure-use): 액션 SHA 고정과 최소 권한.

## 실제 저장소 사례

- [twpayne/dotfiles](https://github.com/twpayne/dotfiles): home, .chezmoiroot, install.sh.
- [felipecrs/dotfiles](https://github.com/felipecrs/dotfiles): home, scripts, docs와 설치 자동화.
- [HeyItsGilbert/dotfiles](https://github.com/HeyItsGilbert/dotfiles): Windows/PowerShell과 install.sh/install.ps1.
- [holman/dotfiles](https://github.com/holman/dotfiles): 주제별 구성과 별도 링크 규칙.
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles): 일반 프로젝트 경로에 checkout을 두는 사례.

선택한 구조는 home을 배포 루트로 분리하고 앱별 원본을 공유하며 운영 코드는 일반 프로젝트 디렉터리에 두는 방식이다. 기존 사용자 코드나 인증 정책을 이 사례에서 가져오지 않았다.

검증용 chezmoi는 공식 v2.73.0을 지정한다. tests/chezmoi-release.json의 체크섬은 그 릴리스의 공식 checksums.txt에서 확인한 SHA-256이다. CI 다운로드는 러너 임시 경로에만 저장한다. 루트 mise 설정은 현재 Fedora 도구에서 확인한 2026.10.3을 최소로 요구하며 CLI 설치 버전을 새로 선언하지 않는다.
