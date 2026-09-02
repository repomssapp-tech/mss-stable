-- ===========================================================
-- Migration: catalog_db_change_webhook
-- Project : IN Schemes (MSS)
-- Purpose : Triggers the db-change-notify Edge Function whenever
--           catalog schemes, releases, or promo alerts are mutated,
--           broadcasting Realtime updates to Flutter clients.
-- ===========================================================

-- Enable pg_net extension if available for async HTTP requests from triggers
create extension if not exists pg_net with schema extensions;

-- Trigger notification function
create or replace function private.notify_catalog_change()
returns trigger
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  payload jsonb;
  target_url text;
  supabase_anon_key text;
begin
  payload := jsonb_build_object(
    'schema', TG_TABLE_SCHEMA,
    'table', TG_TABLE_NAME,
    'type', TG_OP,
    'record', case when TG_OP = 'DELETE' then to_jsonb(OLD) else to_jsonb(NEW) end,
    'old_record', case when TG_OP = 'UPDATE' then to_jsonb(OLD) else null end
  );

  -- Internal or project function URL (falls back to local dev or project ref)
  target_url := current_setting('app.settings.edge_function_url', true);
  if target_url is null or target_url = '' then
    target_url := 'http://kong:8000/functions/v1/db-change-notify';
  end if;

  -- Fire async HTTP POST request via pg_net if available
  begin
    perform net.http_post(
      url := target_url,
      body := payload,
      headers := jsonb_build_object(
        'Content-Type', 'application/json'
      ),
      timeout_milliseconds := 3000
    );
  exception when others then
    -- Catch any network or configuration error silently so DB transaction is not aborted
    null;
  end;

  return coalesce(NEW, OLD);
end;
$$;

-- Create triggers on catalog.scheme if table exists
do $$
begin
  if exists (select 1 from pg_tables where schemaname = 'catalog' and tablename = 'scheme') then
    drop trigger if exists tr_catalog_scheme_change on catalog.scheme;
    create trigger tr_catalog_scheme_change
      after insert or update or delete on catalog.scheme
      for each row execute function private.notify_catalog_change();
  end if;
end;
$$;

-- Create triggers on admin.catalog_releases if table exists
do $$
begin
  if exists (select 1 from pg_tables where schemaname = 'admin' and tablename = 'catalog_releases') then
    drop trigger if exists tr_admin_catalog_releases_change on admin.catalog_releases;
    create trigger tr_admin_catalog_releases_change
      after insert or update or delete on admin.catalog_releases
      for each row execute function private.notify_catalog_change();
  end if;
end;
$$;

-- Create triggers on public.promo_alerts if table exists
do $$
begin
  if exists (select 1 from pg_tables where schemaname = 'public' and tablename = 'promo_alerts') then
    drop trigger if exists tr_public_promo_alerts_change on public.promo_alerts;
    create trigger tr_public_promo_alerts_change
      after insert or update or delete on public.promo_alerts
      for each row execute function private.notify_catalog_change();
  end if;
end;
$$;
