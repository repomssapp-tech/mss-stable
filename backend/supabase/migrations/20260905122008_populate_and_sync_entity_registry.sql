-- 4.1 (audit_fix.md): catalog.entity_registry is the intended canonical
-- entity index but has always been empty. admin_import_scheme_catalog (the
-- function the audit's original plan assumed owned this) does not exist in
-- this database -- the 15 per-type catalog tables are bulk-loaded through
-- an out-of-band release process, not any tracked RPC. Rather than a
-- one-time backfill that immediately starts drifting on the next catalog
-- release (the exact risk this finding calls out), this adds a shared
-- AFTER INSERT/UPDATE/DELETE trigger across all 15 tables so
-- entity_registry stays in sync going forward, then backfills the current
-- 1216 rows once.
--
-- All 15 tables share an identical relevant shape (id, version, status,
-- checksum, updated_at; status already uses entity_registry's own
-- DRAFT/PUBLISHED/ARCHIVED vocabulary directly, confirmed against
-- catalog.scheme's live values), so one generic trigger function handles
-- all of them via TG_TABLE_NAME. validation_status has no source
-- equivalent -- defaulted to 'NOT_VALIDATED', the honest value: no formal
-- validation pass has run against these rows. created_at has no source
-- equivalent either -- backfilled from each row's own updated_at as the
-- closest available proxy, not "now()", which would misrepresent 1216
-- rows as created in the same instant.

create or replace function catalog.sync_entity_registry()
returns trigger
language plpgsql
security definer
set search_path = catalog, public
as $$
begin
  if TG_OP = 'DELETE' then
    update catalog.entity_registry
    set is_deleted = true,
        deleted_at = now(),
        deleted_reason = 'source row deleted from catalog.' || TG_TABLE_NAME,
        updated_at = now()
    where entity_id = OLD.id and entity_type = TG_TABLE_NAME;
    return OLD;
  end if;

  insert into catalog.entity_registry (
    entity_id, entity_type, catalog_name, current_version, status,
    validation_status, is_deleted, checksum, created_at, updated_at
  )
  values (
    NEW.id, TG_TABLE_NAME, TG_TABLE_NAME, NEW.version, NEW.status,
    'NOT_VALIDATED', false, NEW.checksum,
    coalesce(NEW.updated_at, now()), coalesce(NEW.updated_at, now())
  )
  on conflict (entity_id) do update
  set entity_type = excluded.entity_type,
      catalog_name = excluded.catalog_name,
      current_version = excluded.current_version,
      status = excluded.status,
      checksum = excluded.checksum,
      updated_at = excluded.updated_at,
      is_deleted = false,
      deleted_at = null,
      deleted_reason = null;

  return NEW;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array[
    'common', 'authority', 'institution', 'scheme', 'finance', 'tax',
    'treds', 'csr', 'export', 'knowledge', 'applicability_matrix',
    'enterprise_classification', 'msme_privilege', 'business_enablement',
    'cluster_assistance'
  ]
  loop
    execute format(
      'drop trigger if exists trg_sync_entity_registry on catalog.%I', t
    );
    execute format(
      'create trigger trg_sync_entity_registry
         after insert or update or delete on catalog.%I
         for each row execute function catalog.sync_entity_registry()',
      t
    );
  end loop;
end $$;

insert into catalog.entity_registry (
  entity_id, entity_type, catalog_name, current_version, status,
  validation_status, is_deleted, checksum, created_at, updated_at
)
select id, 'common', 'common', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.common
union all
select id, 'authority', 'authority', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.authority
union all
select id, 'institution', 'institution', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.institution
union all
select id, 'scheme', 'scheme', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.scheme
union all
select id, 'finance', 'finance', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.finance
union all
select id, 'tax', 'tax', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.tax
union all
select id, 'treds', 'treds', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.treds
union all
select id, 'csr', 'csr', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.csr
union all
select id, 'export', 'export', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.export
union all
select id, 'knowledge', 'knowledge', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.knowledge
union all
select id, 'applicability_matrix', 'applicability_matrix', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.applicability_matrix
union all
select id, 'enterprise_classification', 'enterprise_classification', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.enterprise_classification
union all
select id, 'msme_privilege', 'msme_privilege', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.msme_privilege
union all
select id, 'business_enablement', 'business_enablement', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.business_enablement
union all
select id, 'cluster_assistance', 'cluster_assistance', version, status, 'NOT_VALIDATED', false, checksum,
       coalesce(updated_at, now()), coalesce(updated_at, now()) from catalog.cluster_assistance
on conflict (entity_id) do nothing;
