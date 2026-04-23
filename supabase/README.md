# Supabase 자산

## 디렉토리

- `migrations/` — Supabase SQL Editor 에서 수동으로 실행할 스키마/함수 변경 스크립트
- `functions/` — Deno 기반 Edge Functions. `supabase functions deploy <name>` 로 배포

## 현재 포함된 자산

### `migrations/005_grace_purge_function.sql`

Pro→Free 전환 후 Grace period(7일) 이 만료된 유저의 원격 folders/links 를 일괄 삭제하는 pg function `public.linkpool_grace_purge()`. 참조: `docs/SYNC_MODEL_V2.md` §2.3 / §5.

**배포 방법**:

1. Supabase 대시보드 > SQL Editor 를 열고 이 파일 내용을 붙여넣은 뒤 Run.
2. 정상 실행되면 아래 쿼리로 함수 등록 확인:

   ```sql
   SELECT proname, prosecdef, proowner::regrole
   FROM pg_proc
   WHERE proname = 'linkpool_grace_purge';
   ```

### `functions/grace-purge/`

위 pg function 을 매일 호출하는 Deno Edge Function. Supabase Scheduled Trigger 로 실행.

**배포 방법**:

```bash
# 1) Supabase CLI 로 로그인
supabase login

# 2) 프로젝트 링크 (최초 1회)
supabase link --project-ref <프로젝트 ref>

# 3) 함수 배포
supabase functions deploy grace-purge

# 4) (대시보드) Edge Functions > grace-purge > Schedules 에
#     cron 표현식 `0 3 * * *` (매일 03:00 UTC) 로 등록
```

배포 후 확인:

```bash
supabase functions invoke grace-purge
```

응답 예시:

```json
{ "ok": true, "result": { "deleted_links": 0, "deleted_folders": 0, "affected_users": 0 } }
```

## 주의사항

- Migration 005 실행 **전에** `plan` / `plan_expires_at` 가 `auth.users.raw_user_meta_data` 에 들어있는지 확인.
  스키마가 바뀌면 `005_grace_purge_function.sql` 도 함께 갱신해야 한다.
- Edge Function 은 `service_role` 권한으로 돌아간다. 반드시 `SUPABASE_SERVICE_ROLE_KEY` 를 환경변수로 제공.
- Grace period 는 클라이언트의 `lp_grace_until` SharedPreferences 와 **독립적**. 클라이언트는 안내용, 실제 삭제는 서버가 한다.
