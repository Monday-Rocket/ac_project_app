-- Migration 005: Grace purge pg function
-- 참조: docs/SYNC_MODEL_V2.md §2.3 / §5
--
-- Pro → Free 전환 후 Grace period(7일) 이 지난 유저의 folders/links 를 일괄 삭제.
-- Edge Function `grace-purge` 가 Supabase Scheduled Trigger 로 이 함수를 호출한다.
--
-- 삭제 기준:
--   auth.users.raw_user_meta_data->>'plan_expires_at' 이 존재하고
--   plan_expires_at + 7 days < now() 인 유저.
--
-- 주의:
-- - 현재 plan=pro 로 재구독한 유저는 AuthCubit 이 전환 감지 시점에
--   lp_grace_until 을 로컬에서 지우고 backupToRemote 로 원격을 덮어쓰므로,
--   이 함수 관점에서는 "plan_expires_at 이 과거" 조건에 매치되지만 원격은 이미 새 데이터로 교체됨.
--   따라서 현 효과적 plan(free) 필터가 필요하다 — plan 이 이제 pro 면 purge 대상에서 제외.
-- - plan/plan_expires_at 저장 위치는 auth.users.raw_user_meta_data JSONB. 스키마 변경이 생기면 함수도 갱신 필요.
--
-- 배포: Supabase SQL Editor 에서 이 파일 내용 실행.

CREATE OR REPLACE FUNCTION public.linkpool_grace_purge()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  deleted_links_count integer := 0;
  deleted_folders_count integer := 0;
  affected_users uuid[];
BEGIN
  -- 1) Grace 만료 + 현재 plan 이 pro 가 아닌 유저 선정
  SELECT array_agg(u.id) INTO affected_users
  FROM auth.users u
  WHERE u.raw_user_meta_data ? 'plan_expires_at'
    AND (u.raw_user_meta_data->>'plan_expires_at')::timestamptz + interval '7 days' < now()
    AND COALESCE(u.raw_user_meta_data->>'plan', 'free') <> 'pro';

  IF affected_users IS NULL OR array_length(affected_users, 1) = 0 THEN
    RETURN jsonb_build_object(
      'deleted_links', 0,
      'deleted_folders', 0,
      'affected_users', 0
    );
  END IF;

  -- 2) 링크 먼저 삭제
  WITH deleted AS (
    DELETE FROM public.links
    WHERE user_id = ANY(affected_users)
    RETURNING 1
  )
  SELECT count(*) INTO deleted_links_count FROM deleted;

  -- 3) 폴더 삭제 (parent_id FK 는 CASCADE 로 이미 정리됨)
  WITH deleted AS (
    DELETE FROM public.folders
    WHERE user_id = ANY(affected_users)
    RETURNING 1
  )
  SELECT count(*) INTO deleted_folders_count FROM deleted;

  RETURN jsonb_build_object(
    'deleted_links', deleted_links_count,
    'deleted_folders', deleted_folders_count,
    'affected_users', array_length(affected_users, 1)
  );
END;
$$;

-- service_role 만 실행 가능. anon/authenticated 로부터 차단.
REVOKE ALL ON FUNCTION public.linkpool_grace_purge() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.linkpool_grace_purge() FROM anon;
REVOKE ALL ON FUNCTION public.linkpool_grace_purge() FROM authenticated;
GRANT EXECUTE ON FUNCTION public.linkpool_grace_purge() TO service_role;

COMMENT ON FUNCTION public.linkpool_grace_purge() IS
  'Pro→Free 전환 후 Grace 7d 만료 유저의 folders/links 를 일괄 삭제. Edge Function grace-purge 가 호출.';
