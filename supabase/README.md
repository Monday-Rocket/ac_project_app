# Supabase 자산

## 디렉토리

- `migrations/` — Supabase SQL Editor 또는 psql 로 실행하는 스키마/함수 변경 스크립트
- `functions/` — Deno 기반 Edge Functions. `supabase functions deploy <name>` 로 배포

## 배포 기록

### Migration 005 — `linkpool_grace_purge()` pg function

Pro→Free 전환 후 Grace period(7일) 이 만료된 유저의 원격 folders/links 를 일괄 삭제하는
pg function. 참조: `docs/SYNC_MODEL_V2.md` §2.3 / §5.

**배포 상태**: ✅ 완료 (2026-04-23)

**재적용 방법**:

```bash
# .env 의 LINKPOOL_SUPABASE_DB_URL 로 psql 접속
/opt/homebrew/opt/libpq/bin/psql "$LINKPOOL_SUPABASE_DB_URL" \
  -v ON_ERROR_STOP=1 \
  -f supabase/migrations/005_grace_purge_function.sql
```

검증 쿼리:

```sql
SELECT proname, prosecdef, proowner::regrole
FROM pg_proc
WHERE proname = 'linkpool_grace_purge';

-- 드라이런 (현재 Grace 만료 유저가 없으면 전부 0)
SELECT public.linkpool_grace_purge();
```

### Edge Function `grace-purge`

외부(수동 트리거/디버깅) 에서 `linkpool_grace_purge()` 를 HTTP 로 호출하는 얇은 래퍼.

**배포 상태**: ✅ 완료 (2026-04-23)

**재배포 방법**:

```bash
supabase functions deploy grace-purge --project-ref gystdpdelnfblgyeckth
```

수동 호출:

```bash
curl -sS -X POST "$SUPABASE_URL/functions/v1/grace-purge" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
# → {"ok":true,"result":{"deleted_links":0,"affected_users":0,"deleted_folders":0}}
```

### Scheduled Job — pg_cron

매일 03:00 UTC 에 `linkpool_grace_purge()` 를 직접 호출하는 pg_cron job.
Edge Function HTTP 경로를 거치지 않아 auth/네트워크 의존성이 없다 (DB 내부에서 완결).

**배포 상태**: ✅ 완료 (2026-04-23, `jobid=1`, `linkpool_grace_purge_daily`)

**재등록 방법**:

```sql
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'linkpool_grace_purge_daily';

SELECT cron.schedule(
  'linkpool_grace_purge_daily',
  '0 3 * * *',
  $cron$SELECT public.linkpool_grace_purge();$cron$
);
```

상태 조회:

```sql
SELECT jobid, schedule, command, active
FROM cron.job
WHERE jobname = 'linkpool_grace_purge_daily';

-- 최근 실행 기록
SELECT jobid, status, return_message, start_time, end_time
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'linkpool_grace_purge_daily')
ORDER BY start_time DESC
LIMIT 10;
```

## 주의사항

- Migration 005 는 `plan` / `plan_expires_at` 가 `auth.users.raw_user_meta_data` JSONB 에 저장된다고 가정한다.
  스키마가 바뀌면 `005_grace_purge_function.sql` 도 갱신해야 한다.
- pg_cron job 은 DB 내 함수를 직접 호출하므로 service_role key 가 필요 없다.
- Edge Function 은 수동 트리거/디버깅/외부 모니터링용으로 남겨둠. 일상 운영에는 pg_cron 이 사용된다.
