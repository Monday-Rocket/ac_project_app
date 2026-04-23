// Edge Function: grace-purge
// 참조: docs/SYNC_MODEL_V2.md §2.3 / §5
//
// Supabase Scheduled Trigger 로 매일 호출되며, Pro→Free 전환 후
// Grace period(7일) 이 만료된 유저의 원격 folders/links 를 purge 한다.
//
// 실제 삭제 로직은 pg function `public.linkpool_grace_purge()` 에 있고,
// 이 Edge Function 은 해당 RPC 를 호출하고 결과를 JSON 으로 반환한다.
//
// 배포:
//   1) `supabase/migrations/005_grace_purge_function.sql` 을 Supabase SQL Editor 에서 실행
//   2) Supabase CLI: `supabase functions deploy grace-purge`
//   3) Supabase 대시보드 > Edge Functions > grace-purge > Schedules 에서
//      cron `0 3 * * *` (매일 03:00 UTC) 로 등록
//
// 요구 환경변수:
//   - SUPABASE_URL
//   - SUPABASE_SERVICE_ROLE_KEY  (service_role 키. anon 키로는 pg function 접근 불가)

// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

serve(async (_req: Request) => {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) {
    return json({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }, 500);
  }

  const supabase = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data, error } = await supabase.rpc("linkpool_grace_purge");
  if (error) {
    console.error("grace-purge RPC failed:", error);
    return json({ error: error.message }, 500);
  }

  console.log("grace-purge ok:", data);
  return json({ ok: true, result: data }, 200);
});

function json(body: any, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}
