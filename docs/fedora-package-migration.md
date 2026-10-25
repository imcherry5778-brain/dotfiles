# Fedora 수동 설치 도구의 패키지 관리 이전

2026-10-26에 사용자가 승인한 개인 Fedora의 설치 주체 이전을 적용했다. 도구의 앱 버전은 유지하고 기존 실행 파일·링크·설정을 대상으로 백업한 뒤 새 실행 파일을 검증해 전환했다.

| 도구 | 유지한 버전 | 설치 주체 | 실제 실행 경로 |
| --- | --- | --- | --- |
| chezmoi | 2.73.0 | Fedora updates의 DNF RPM | `/usr/bin/chezmoi` |
| k3d | 5.9.0 | mise aqua | mise의 `installs/k3d/5.9.0` |
| Argo CD CLI | 3.4.4 | mise aqua | mise의 `installs/argocd/3.4.4` |
| cosign | 3.1.2 | mise aqua | mise의 `installs/cosign/3.1.2` |
| ORAS | 1.2.2 | mise aqua | mise의 `installs/oras/1.2.2` |
| mitmproxy | 12.2.3 | uv tool | `~/.local/share/uv/tools/mitmproxy/bin` |

4개 mise 선언은 `home/dot_config/mise/config.personal-fedora.toml` 한 곳에 추가했다. 현재 선택은 공통 13개·AI 1개·개인 Fedora 24개, 총 38개다. 다른 플랫폼의 선택 도구는 늘리지 않았다. 검증기는 새 CLI들의 실제 `version` 명령을 사용하고, Argo CD에는 `--client --short`를 지정해 서버에 접속하지 않는다.

mitmproxy의 `mitmproxy`·`mitmdump`·`mitmweb`은 모두 uv entrypoint다. Python은 `/usr/bin/python3.14`를 명시해 mise의 이전 Python 정리에 의존하지 않게 했다. 기존 standalone 배포본과 링크는 백업 후 제거했고 `~/.mitmproxy`의 기존 CA는 유지했다. 기존 Aider·qwen-asr uv 설치는 유지한다.

chezmoi 설치는 Fedora의 `chezmoi-2.73.0-1.fc44.x86_64` 한 패키지만 추가했다. `~/.local/bin/chezmoi`는 백업 후 제거해 RPM 실행 파일이 선택된다. 기존 chezmoi 기기 config·source 경로·기능 선택을 유지했고, 적용은 mise 개인 Fedora 파일 하나에 한정해 `--exclude=scripts`로 수행했다. 일반 자동화·전체 설정·다른 OS의 재적용은 하지 않았다. 별도로 존재하던 OpenCode 소스 변경도 보존했다.

## 검증

- 오프라인 installer 검사 25개, 격리 Fedora 반복 적용·선택 검사, 5개 기존 플랫폼의 렌더 회귀 검사를 통과했다. 렌더 기준의 변경은 개인 Fedora mise 파일 한 항목뿐이다.
- 실제 홈에서 mise 도구 38개의 설치 경로·실행 버전을 검증했고, 이전 34개 도구의 활성 버전이 유지됨을 비교했다.
- 새 Zsh 로그인 셸에서 chezmoi·4개 mise CLI·3개 mitmproxy entrypoint의 명령 선택 경로를 확인했다.
- uv mitmdump를 임시 설정 디렉터리와 localhost 포트로 실행해 로컬 HTTP 요청 전달을 확인하고 종료했다. 기존 CA 파일·chezmoi config·OpenCode 소스 및 실행 설정의 해시가 유지됐다.
- 로컬 `sys-update`의 uv 수동 안내에 mitmproxy와 정확한 버전 고정의 의미를 반영했다. 전체 시스템 업데이트는 실행하지 않았다.

Hosted 개인 Fedora 설치 테스트와 workflow 표시의 기대 도구 수는 38개로 갱신했다. Hosted 실행 결과는 GitHub Actions의 Foundation checks와 Installation checks에서 확인한다. 프록시의 실제 외부 TLS 연결·사용자 addon·GUI 기능, Kubernetes 서버 변경은 이번 로컬 검증 범위가 아니다.

## 백업과 향후 갱신

개인 백업은 `~/.local/state/package-manager-migration/20261026T050929+0900`에 있다. `backup-manifest.json`에 원래 파일과 백업 경로를 기록했고, 새 실행 파일 검사·전체 mise 검사·로그인 셸 경로·프록시 검사 근거도 같은 디렉터리에 보관했다. 이 백업은 저장소에 포함하지 않는다.

mise 4개는 정확한 버전을 고정하므로 `mise outdated --bump`로 후보를 확인한 뒤 이 저장소의 선언을 검토해 변경한다. mitmproxy도 `==12.2.3`으로 설치했으므로 uv upgrade는 이 제약을 유지한다. 새 버전을 선택할 때는 uv의 설치 제약을 함께 변경한다. chezmoi는 활성 Fedora 저장소의 DNF 갱신을 따른다.

앞선 사용자 요청으로 제거한 Teleport는 이번 이전 대상에 포함하지 않았고 재설치하지 않았다.

이후 적용한 sys-update 오류 처리와 NVIDIA CDI·DeepFilterNet 복구는 [Fedora 유지보수 기록](fedora-maintenance.md)을 참고한다.
