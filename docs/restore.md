# 복구 계약

개인 Fedora 적용 전에 변경·생성할 파일/링크와 권한만 비공개로 보존했다. 복구본은 실제 홈의 `~/.local/state/dotfiles/backups/<UTC timestamp>/`에 있고 기기 데이터, manifest, 원래 파일, 해당 이전용 restore.py를 포함한다. 디렉터리는 700이며 파일 원래 권한은 manifest에 따로 기록한다. 복구본·인증 파일은 저장소에 커밋하지 않는다.

해당 restore.py는 기본적으로 복구 대상을 출력한다. 백업 경로를 정확히 확인한 뒤 명시적 --apply로 변경된 설정과 링크를 복원하고 새로 생성한 관리 파일을 제거한다. 전체 홈을 되돌리거나 모든 mise 설치를 제거하지 않는다.

```sh
python3 "$HOME/.local/state/dotfiles/backups/<UTC timestamp>/restore.py"
# 위 결과와 해당 복구본을 확인한 뒤:
python3 "$HOME/.local/state/dotfiles/backups/<UTC timestamp>/restore.py" --apply
```

원래 chezmoi 기기 config와 도구 선택도 복구 대상이므로 복구 후 검토 없이 chezmoi apply를 다시 실행하지 않는다. 새로 설치한 CLI 6개는 디스크에 남고 RPM fallback도 유지된다. 복원한 셸 설정은 새 터미널에서 확인한다. 이 복구 도구는 이번 이전용이며 일반적인 임의 변경 rollback이나 원자적 rollback을 제공하지 않는다.

로그인 상태·대화·사용자 파일·프로젝트 작업을 과거 시점으로 자동 되돌리지 않는다. 앱 설정 스키마와 OS 패키지 downgrade는 별도 확인이 필요하다. 전체 백업이나 인증 데이터 복사를 만들지 않는다.
