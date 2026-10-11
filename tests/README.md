# 기반 검증

현재 검증은 구조와 chezmoi 초기화의 경계를 다룬다. 실제 앱 설치·인증·GUI는 검사하지 않는다.

`verify.ps1`은 PowerShell 7과 Git, 지정한 chezmoi 실행 파일을 사용한다. PowerShell은 Windows의 기본 구현이며 이 검증 스크립트에서는 Linux/macOS CI에서도 같은 테스트를 실행하기 위해 사용한다. PowerShell을 Linux/macOS 사용자 기본 CLI 목록에 추가한다는 의미는 아니다.

```powershell
./tests/verify.ps1 -Chezmoi /path/to/chezmoi
```

이미 설치된 chezmoi가 있으면 인자를 생략할 수 있다. 검증기는 도구를 자동 다운로드하지 않는다. CI의 `fetch-chezmoi.ps1`은 별도 명시한 임시 경로에 공식 고정 버전을 내려받아 저장된 SHA-256을 확인한다.

검증 범위:

- PowerShell 구문과 해당 OS의 기본 진입점.
- 공백이 있는 checkout과 대상 경로.
- Fedora·Ubuntu·Arch·openSUSE·macOS·Windows 템플릿 fixture.
- 지원하지 않는 플랫폼과 OS/플랫폼 불일치 거부.
- 현재 러너에서 실제 init와 반복 init의 config 안정성.
- home 안의 공유 데이터와 checkout sourceDir 연결.
- 현재 배포 대상과 diff가 비어 있는지 확인.
- 임시 홈에서만 두 번 apply해 기존 파일·디렉터리가 그대로인지 확인.

원본 checkout, 실제 chezmoi config/cache/state, 사용자 홈을 초기화나 apply 대상에 사용하지 않는다. 테스트의 config·state·cache·source 사본·대상은 전부 임시 디렉터리에 둔다. fixture는 템플릿 자료를 모의할 뿐 해당 OS에서 실행한 검증을 대체하지 않는다.
