# 커밋 전 검사

커밋 전 린트와 테스트를 실행합니다.

## 실행 단계

1. 코드 포맷팅
2. 린트 검사
3. 테스트 실행

```bash
fvm dart format .
fvm flutter analyze
fvm flutter test
```

모든 검사를 통과해야 커밋할 수 있습니다.
