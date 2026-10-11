# 최초 설치와 현재 진입점

현재 install.sh/install.ps1은 설치 프로그램의 초기 인터페이스이며 실제 bootstrap을 수행하지 않는다. 기본 동작은 계획 출력이고 Check 동작도 읽기 전용이다. 아직 없는 설치 기능을 완료된 것으로 표시하지 않는다.

## checkout 위치

인증을 준비한 후 원격 저장소를 각 OS의 실제 홈 아래 `projects/imcherry5778-brain/dotfiles`에 clone한다. 예시는 GitHub 계정 권한과 Git 인증이 준비되어 있다는 전제다.

Unix:

```sh
git clone https://github.com/imcherry5778-brain/dotfiles.git "$HOME/projects/imcherry5778-brain/dotfiles"
```

PowerShell:

```powershell
$destination = Join-Path $HOME 'projects/imcherry5778-brain/dotfiles'
git clone https://github.com/imcherry5778-brain/dotfiles.git $destination
```

기존 경로가 있으면 새 clone으로 덮어쓰지 않고 해당 checkout을 확인한다. Git 인증 방식은 기기 설정을 사용하며 전역 인증 공급자를 이 프로젝트가 자동 변경하지 않는다.

## 미래 bootstrap의 계약

Git·mise·chezmoi·사용할 셸의 현재 설치를 확인하고 필요한 최소 도구만 확보한다. 그다음 sourceDir를 현재 checkout으로 연결하고 기기 데이터를 초기화한다. sourceDir는 /home 등의 문자열을 하드코딩하지 않고 현재 위치를 사용한다.

`chezmoi init`은 config·source·상태를 만들 수 있고 `chezmoi init --apply`는 대상 파일도 변경한다. 실제 호스트에서 초기화·적용하는 것은 후속 이전 단계이며 이번 구조 검증에서 실행하지 않는다.

리뷰한 설정 diff와 배포를 분리하고 기존 파일을 보존한다. 프로그램 설치·업그레이드·버전 삭제를 셸 시작이나 chezmoi 자동 훅에 연결하지 않는다. 인증은 각 OS에서 별도로 준비한다.
