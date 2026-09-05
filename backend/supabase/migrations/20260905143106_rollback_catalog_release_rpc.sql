-- 1.5 (audit_fix.md): rollbackRelease. Atomic pointer flip against
-- admin.catalog_releases + an audit row in admin.catalog_release_history.
-- service_role only -- this is an emergency-undo admin action, never
-- anon/authenticated callable. Requires an explicit target_release_id,
-- never an implicit "previous release" (an admin must name exactly which
-- release to roll back to).

create or replace function public.mss_rollback_release(target_release_id uuid)
returns table (release_version text, published_at timestamptz)
language plpgsql
security definer
set search_path = public, admin, extensions
as $$
declare
  target_status text;
begin
  select r.status into target_status
  from admin.catalog_releases r
  where r.id = target_release_id;

  if target_status is null then
    raise exception 'release % not found', target_release_id;
  end if;
  if target_status <> 'published' then
    raise exception 'release % is not published (status=%)', target_release_id, target_status;
  end if;

  update admin.catalog_releases
  set is_current = false
  where is_current = true and id <> target_release_id;

  update admin.catalog_releases
  set is_current = true
  where id = target_release_id;

  insert into admin.catalog_release_history (id, release_id, action, "timestamp")
  values (gen_random_uuid(), target_release_id, 'rollback', now());

  return query
    select r.release_version, r.published_at
    from admin.catalog_releases r
    where r.id = target_release_id;
end;
$$;

revoke all on function public.mss_rollback_release(uuid) from public, anon, authenticated;
grant execute on function public.mss_rollback_release(uuid) to service_role;
