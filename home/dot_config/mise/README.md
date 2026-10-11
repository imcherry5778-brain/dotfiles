# 전역 mise 설정의 소스 위치

이 디렉터리는 향후 `~/.config/mise`로 배포할 설정 원본 위치다. 현재 설치 목록·버전·잠금은 배포하지 않는다.

계획은 `config.toml`에 일반 CLI 13개, `config.ai.toml`에 mise가 관리할 AI CLI를 선언하는 것이다. 기반 패키지 차이는 `config.unix.toml`, `config.fedora.toml`, `config.ubuntu.toml`, `config.arch.toml`, `config.opensuse.toml`, `config.macos.toml`, `config.windows.toml`에 두고 기존 Fedora 추가 도구만 `config.personal-fedora.toml` 선택으로 보존한다.

`miserc.toml.tmpl`에서 환경 선택을 명시한다. 배포판 파일을 이름만 만들어 자동 선택될 것으로 기대하지 않는다. `opensuse-tumbleweed`는 OS 판정 값이고 mise 환경 이름 `opensuse`와 명시적으로 연결한다.

버전은 실제 실행 파일을 재확인한 후 고정하고 lockfile은 mise로 생성한다. 원본 lockfile을 템플릿이나 손으로 작성하지 않는다. 저장소 루트 mise.toml에는 이 목록을 중복 선언하지 않는다.
