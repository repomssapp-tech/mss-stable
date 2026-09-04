-- Snapshot of the live Supabase schema (public, catalog, admin, graphql_public).
-- Generated via `supabase db dump --linked` on 2026-09-04, after applying all
-- migrations through 20260904000000_catalog_row_checksum_trigger.sql.
-- This is a point-in-time reference, not a migration -- schema changes still go
-- through backend/supabase/migrations/. Regenerate with:
--   supabase db dump --linked --schema public,catalog,admin,graphql_public -f backend/supabase/schema.sql




SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "admin";


ALTER SCHEMA "admin" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "catalog";


ALTER SCHEMA "catalog" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "graphql_public";


ALTER SCHEMA "graphql_public" OWNER TO "supabase_admin";


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'Public schema with Free-Tier aligned statement and lock timeouts.';



CREATE TYPE "public"."region_level" AS ENUM (
    'country',
    'state',
    'district',
    'block',
    'village',
    'other'
);


ALTER TYPE "public"."region_level" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "catalog"."mss_localized_text"("rec" "jsonb", "lang" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    SET "search_path" TO 'catalog', 'public', 'extensions'
    AS $$
    select string_agg(value #>> '{}', ' ')
    from jsonb_each(coalesce(rec #> array['localization', lang], '{}'::jsonb))
    where jsonb_typeof(value) = 'string'
$$;


ALTER FUNCTION "catalog"."mss_localized_text"("rec" "jsonb", "lang" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "catalog"."mss_recompute_row_checksum"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
begin
  new.checksum := encode(extensions.digest(new.record_json::text, 'sha256'), 'hex');
  return new;
end;
$$;


ALTER FUNCTION "catalog"."mss_recompute_row_checksum"() OWNER TO "postgres";


COMMENT ON FUNCTION "catalog"."mss_recompute_row_checksum"() IS 'Keeps catalog.*.checksum in sync with record_json on every write (table-editor edits included). See public.mss_catalog_meta() and HASH_VERIFICATION_SPECIFICATION.md §2.';



CREATE OR REPLACE FUNCTION "catalog"."mss_search"("q" "text", "lang" "text" DEFAULT 'en'::"text", "types" "text"[] DEFAULT NULL::"text"[], "lim" integer DEFAULT 25, "off" integer DEFAULT 0) RETURNS TABLE("entity_id" "text", "entity_type" "text", "catalog_name" "text", "name" "text", "name_en" "text", "name_ta" "text", "rank" real, "has_tamil" boolean)
    LANGUAGE "plpgsql" STABLE PARALLEL SAFE
    SET "search_path" TO 'catalog', 'public', 'extensions'
    AS $_$
declare
    tbl text;
    sql text := '';
begin
    foreach tbl in array array['scheme','authority','institution','common','finance',
                               'tax','treds','csr','export','knowledge']
    loop
        if sql <> '' then sql := sql || ' union all '; end if;
        sql := sql || format($f$
            select record_json #>> '{identity,id}'          as entity_id,
                   record_json #>> '{identity,entityType}'   as entity_type,
                   %L                                        as catalog_name,
                   record_json #>> '{identity,name}'         as name_en,
                   record_json #>> '{localization,ta,name}'  as name_ta,
                   ts_rank(search_doc, websearch_to_tsquery('simple', $1))  as rank_ta,
                   ts_rank(search_doc, websearch_to_tsquery('english', $1)) as rank_en
            from catalog.%I
            where search_doc @@ websearch_to_tsquery('simple', $1)
               or search_doc @@ websearch_to_tsquery('english', $1)
        $f$, tbl, tbl);
    end loop;

    return query execute format(
        'select s.entity_id, s.entity_type, s.catalog_name,
                case when $2 = ''ta'' then coalesce(s.name_ta, s.name_en) else s.name_en end,
                s.name_en, s.name_ta,
                greatest(s.rank_ta, s.rank_en)::real,
                s.name_ta is not null
         from (%s) s
         where $3 is null or s.entity_type = any($3)
         order by greatest(s.rank_ta, s.rank_en) desc,
                  (case when $2 = ''ta'' and s.name_ta is not null then 0 else 1 end),
                  s.name_en
         limit least(coalesce($4, 25), 100) offset greatest(coalesce($5, 0), 0)', sql)
    using q, lang, types, lim, off;
end $_$;


ALTER FUNCTION "catalog"."mss_search"("q" "text", "lang" "text", "types" "text"[], "lim" integer, "off" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "catalog"."mss_search"("q" "text", "lang" "text", "types" "text"[], "lim" integer, "off" integer) IS 'Matches tokens.en AND tokens.ta always, across all 10 catalogs. `lang` selects the display name and applies a ranking boost ONLY — never scopes the match. Verified reason: SIDBI appears in 18 English and 11 Tamil token sets; TReDS and legacy scheme codes appear in ZERO Tamil sets. A language-scoped query silently loses results with no error.';



CREATE OR REPLACE FUNCTION "catalog"."mss_search_document"("rec" "jsonb") RETURNS "tsvector"
    LANGUAGE "sql" IMMUTABLE STRICT
    SET "search_path" TO 'catalog', 'public', 'extensions'
    AS $$
    select setweight(to_tsvector('english', coalesce(rec #>> '{identity,name}', '')), 'A')
        || setweight(to_tsvector('simple',  coalesce(rec #>> '{identity,name}', '')), 'A')
        || setweight(to_tsvector('simple',  coalesce(rec #>> '{localization,ta,name}', '')), 'A')
        || setweight(to_tsvector('simple',  coalesce(rec #>> '{identity,acronym}', '')
                                    || ' ' || coalesce(rec #>> '{identity,code}', '')), 'A')
        || setweight(to_tsvector('english', coalesce(catalog.mss_localized_text(rec, 'en'), '')), 'B')
        || setweight(to_tsvector('simple',  coalesce(catalog.mss_localized_text(rec, 'ta'), '')), 'B')
        || setweight(to_tsvector('simple',
             coalesce((select string_agg(x #>> '{}', ' ')
                       from jsonb_array_elements(
                            coalesce(rec #> '{search,keywords,en}', '[]'::jsonb)
                         || coalesce(rec #> '{search,keywords,ta}', '[]'::jsonb)
                         || coalesce(rec #> '{search,aliases,en}',  '[]'::jsonb)
                         || coalesce(rec #> '{search,aliases,ta}',  '[]'::jsonb)
                         || coalesce(rec #> '{search,synonyms}',    '[]'::jsonb)) as x), '')), 'C')
$$;


ALTER FUNCTION "catalog"."mss_search_document"("rec" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "graphql_public"."graphql"("operationName" "text" DEFAULT NULL::"text", "query" "text" DEFAULT NULL::"text", "variables" "jsonb" DEFAULT NULL::"jsonb", "extensions" "jsonb" DEFAULT NULL::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;


ALTER FUNCTION "graphql_public"."graphql"("operationName" "text", "query" "text", "variables" "jsonb", "extensions" "jsonb") OWNER TO "supabase_admin";


CREATE OR REPLACE FUNCTION "public"."delete_user"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  if auth.uid() is not null then
    delete from auth.users where id = auth.uid();
  else
    raise exception 'Only authenticated users can delete their account';
  end if;
end;
$$;


ALTER FUNCTION "public"."delete_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mss_catalog_meta"() RETURNS TABLE("catalog_version" "text", "catalog_checksum" "text", "entity_counts" "jsonb")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'catalog', 'extensions'
    AS $$
  with rows as (
    select 'common' as src, id, checksum from catalog.common
    union all select 'authority', id, checksum from catalog.authority
    union all select 'institution', id, checksum from catalog.institution
    union all select 'scheme', id, checksum from catalog.scheme
    union all select 'finance', id, checksum from catalog.finance
    union all select 'tax', id, checksum from catalog.tax
    union all select 'export', id, checksum from catalog.export
    union all select 'csr', id, checksum from catalog.csr
    union all select 'treds', id, checksum from catalog.treds
    union all select 'knowledge', id, checksum from catalog.knowledge
    union all select 'applicability_matrix', id, checksum from catalog.applicability_matrix
    union all select 'enterprise_classification', id, checksum from catalog.enterprise_classification
    union all select 'msme_privilege', id, checksum from catalog.msme_privilege
    union all select 'business_enablement', id, checksum from catalog.business_enablement
    union all select 'cluster_assistance', id, checksum from catalog.cluster_assistance
  ),
  agg as (
    select encode(digest(string_agg(checksum, '' order by src, id), 'sha256'), 'hex') as full_checksum
    from rows
  ),
  counts as (
    select jsonb_object_agg(src, n) as counts_json
    from (select src, count(*) as n from rows group by src) c
  )
  select
    substr(agg.full_checksum, 1, 16) as catalog_version,
    agg.full_checksum as catalog_checksum,
    coalesce(counts.counts_json, '{}'::jsonb) as entity_counts
  from agg, counts;
$$;


ALTER FUNCTION "public"."mss_catalog_meta"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mss_check_rate_limit"("p_bucket" "text", "p_identifier" "text", "p_max_requests" integer, "p_window_seconds" integer) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_now    timestamptz := clock_timestamp();
  v_cutoff timestamptz;
  v_count  integer;
begin
  v_cutoff := v_now - make_interval(secs => p_window_seconds);

  insert into public.api_rate_limits as l
    (bucket, identifier, window_start, request_count, updated_at)
  values
    (p_bucket, p_identifier, v_now, 1, v_now)
  on conflict (bucket, identifier) do update
    set request_count = case
          when l.window_start < v_cutoff then 1
          else l.request_count + 1
        end,
        window_start = case
          when l.window_start < v_cutoff then v_now
          else l.window_start
        end,
        updated_at = v_now
  returning l.request_count into v_count;

  -- Opportunistic GC (~1% of calls) so the table cannot grow unbounded
  -- without needing pg_cron on the free tier.
  if random() < 0.01 then
    delete from public.api_rate_limits
     where updated_at < v_now - interval '2 days';
  end if;

  return v_count > p_max_requests;
end;
$$;


ALTER FUNCTION "public"."mss_check_rate_limit"("p_bucket" "text", "p_identifier" "text", "p_max_requests" integer, "p_window_seconds" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mss_current_release"() RETURNS TABLE("release_version" "text", "package_sha256" "text", "package_byte_size" integer, "schema_version" integer, "record_counts" "jsonb", "published_at" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'admin', 'extensions'
    AS $$
  select
    r.release_version,
    r.package_sha256,
    r.package_byte_size,
    r.schema_version,
    r.record_counts,
    r.published_at
  from admin.catalog_releases r
  where r.is_current = true and r.status = 'published'
  limit 1;
$$;


ALTER FUNCTION "public"."mss_current_release"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mss_entity_record"("p_entity_id" "text") RETURNS TABLE("entity_type" "text", "record_json" "jsonb")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'catalog', 'extensions'
    AS $$
begin
  if p_entity_id like 'SCH%' then
    return query select 'scheme', s.record_json from catalog.scheme s where s.id = p_entity_id;
  elsif p_entity_id like 'AUTH%' then
    return query select 'authority', a.record_json from catalog.authority a where a.id = p_entity_id;
  elsif p_entity_id like 'INST%' then
    return query select 'institution', i.record_json from catalog.institution i where i.id = p_entity_id;
  elsif p_entity_id like 'FIN%' then
    return query select 'finance_product', f.record_json from catalog.finance f where f.id = p_entity_id;
  elsif p_entity_id like 'TAX%' then
    return query select 'tax_provision', t.record_json from catalog.tax t where t.id = p_entity_id;
  elsif p_entity_id like 'EXP%' then
    return query select 'export_benefit', e.record_json from catalog.export e where e.id = p_entity_id;
  elsif p_entity_id like 'CSR%' then
    return query select 'csr_provision', c.record_json from catalog.csr c where c.id = p_entity_id;
  elsif p_entity_id like 'TDS%' then
    return query select 'treds_platform', td.record_json from catalog.treds td where td.id = p_entity_id;
  elsif p_entity_id like 'KNOW%' then
    return query select 'knowledge_item', k.record_json from catalog.knowledge k where k.id = p_entity_id;
  elsif p_entity_id like 'APLM%' then
    return query select 'applicability_matrix', am.record_json from catalog.applicability_matrix am where am.id = p_entity_id;
  elsif p_entity_id like 'ENTC%' then
    return query select 'enterprise_classification', ec.record_json from catalog.enterprise_classification ec where ec.id = p_entity_id;
  elsif p_entity_id like 'PRIV%' then
    return query select 'msme_privilege', mp.record_json from catalog.msme_privilege mp where mp.id = p_entity_id;
  elsif p_entity_id like 'ENAB%' then
    return query select 'business_enablement', be.record_json from catalog.business_enablement be where be.id = p_entity_id;
  elsif p_entity_id like 'CLUS%' then
    return query select 'cluster_assistance', cl.record_json from catalog.cluster_assistance cl where cl.id = p_entity_id;
  elsif p_entity_id like 'CMN%' then
    return query select 'common_term', cm.record_json from catalog.common cm where cm.id = p_entity_id;
  end if;
end;
$$;


ALTER FUNCTION "public"."mss_entity_record"("p_entity_id" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mss_finance_by_scheme"("p_scheme_id" "text") RETURNS TABLE("id" "text", "record_json" "jsonb")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'catalog', 'extensions'
    AS $$
  select id, record_json from catalog.finance where scheme_id = p_scheme_id order by id;
$$;


ALTER FUNCTION "public"."mss_finance_by_scheme"("p_scheme_id" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mss_lookup_catalog"("p_catalog" "text") RETURNS TABLE("id" "text", "record_json" "jsonb")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'catalog', 'extensions'
    AS $$
begin
  if p_catalog = 'finance' then
    return query select f.id, f.record_json from catalog.finance f order by f.id;
  elsif p_catalog = 'cluster_assistance' then
    return query select c.id, c.record_json from catalog.cluster_assistance c order by c.id;
  elsif p_catalog = 'tax' then
    return query select t.id, t.record_json from catalog.tax t order by t.id;
  elsif p_catalog = 'msme_privilege' then
    return query select m.id, m.record_json from catalog.msme_privilege m order by m.id;
  elsif p_catalog = 'applicability_matrix' then
    return query select am.id, am.record_json from catalog.applicability_matrix am order by am.id;
  end if;
end;
$$;


ALTER FUNCTION "public"."mss_lookup_catalog"("p_catalog" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mss_rate_limit_status"("p_bucket" "text") RETURNS TABLE("identifier" "text", "request_count" integer, "window_start" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select l.identifier, l.request_count, l.window_start
    from public.api_rate_limits l
   where l.bucket = p_bucket
   order by l.request_count desc
   limit 100;
$$;


ALTER FUNCTION "public"."mss_rate_limit_status"("p_bucket" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mss_relationships"("p_entity_id" "text") RETURNS TABLE("target_id" "text", "target_type" "text", "target_name" "text", "relationship_type" "text", "generated" boolean)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'catalog', 'extensions'
    AS $$
begin
  return query
  select
    r.target_id,
    r.target_type,
    (select (er.record_json->'identity'->>'name') from public.mss_entity_record(r.target_id) er limit 1) as target_name,
    r.relationship_type,
    coalesce((r.metadata->>'generated')::boolean, false) as generated
  from catalog.relationships r
  where r.source_id = p_entity_id
  order by r.relationship_type, r.target_id;
end;
$$;


ALTER FUNCTION "public"."mss_relationships"("p_entity_id" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mss_scheme_detail"("p_scheme_id" "text") RETURNS "jsonb"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'catalog', 'extensions'
    AS $$
  select case when s.id is null then null else jsonb_build_object(
    'id', s.id,
    'scheme', s.record_json,
    'finance', coalesce((select jsonb_agg(f.record_json) from catalog.finance f where f.scheme_id = s.id), '[]'::jsonb),
    'tax', coalesce((select jsonb_agg(t.record_json) from catalog.tax t where t.scheme_id = s.id), '[]'::jsonb),
    'export', coalesce((select jsonb_agg(e.record_json) from catalog.export e where e.scheme_id = s.id), '[]'::jsonb),
    'csr', coalesce((select jsonb_agg(c.record_json) from catalog.csr c where c.scheme_id = s.id), '[]'::jsonb),
    'treds', coalesce((select jsonb_agg(td.record_json) from catalog.treds td where td.scheme_id = s.id), '[]'::jsonb),
    'applicabilityMatrix', coalesce((select jsonb_agg(am.record_json) from catalog.applicability_matrix am where am.scheme_id = s.id), '[]'::jsonb),
    'authority', (select a.record_json from catalog.authority a where a.id = s.primary_authority_id),
    'institution', (select i.record_json from catalog.institution i where i.id = s.primary_institution_id)
  ) end
  from catalog.scheme s
  where s.id = p_scheme_id;
$$;


ALTER FUNCTION "public"."mss_scheme_detail"("p_scheme_id" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mss_search_data"() RETURNS TABLE("scheme_id" "text", "name_en" "text", "scheme_record" "jsonb", "search_record" "jsonb")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public', 'catalog', 'extensions'
    AS $$
  select
    s.id as scheme_id,
    s.name_en,
    jsonb_build_object(
      'identity', jsonb_build_object(
        'status', coalesce(s.record_json->'identity'->'status', to_jsonb('unknown'::text)),
        'name', coalesce(s.record_json->'identity'->'name', to_jsonb(s.name_en))
      ),
      'ai', jsonb_build_object(
        'semanticTags', coalesce(s.record_json->'ai'->'semanticTags', '[]'::jsonb)
      )
    ) as scheme_record,
    jsonb_build_object(
      'tokens', coalesce(si.record_json->'tokens', '{}'::jsonb),
      'schemeSearchProfile', coalesce(si.record_json->'schemeSearchProfile', '{}'::jsonb)
    ) as search_record
  from catalog.scheme s
  left join catalog.search_index si on si.scheme_id = s.id;
$$;


ALTER FUNCTION "public"."mss_search_data"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."safe_cast_to_numeric"("val" "text") RETURNS numeric
    LANGUAGE "plpgsql" IMMUTABLE
    SET "search_path" TO 'public', 'extensions'
    AS $$
BEGIN
    RETURN val::numeric;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."safe_cast_to_numeric"("val" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "admin"."admins" (
    "id" "uuid" NOT NULL,
    "role_id" smallint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "admin"."admins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."catalog_change_log" (
    "id" bigint NOT NULL,
    "entity" "text" NOT NULL,
    "entity_id" "text" NOT NULL,
    "field_path" "text" NOT NULL,
    "previous_value" "jsonb",
    "new_value" "jsonb",
    "reason" "text",
    "changed_by" "uuid",
    "approved_by" "uuid",
    "timestamp" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "admin"."catalog_change_log" OWNER TO "postgres";


ALTER TABLE "admin"."catalog_change_log" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "admin"."catalog_change_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "admin"."catalog_files" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "release_id" "uuid",
    "file_name" "text" NOT NULL,
    "checksum" "text" NOT NULL,
    "byte_size" integer NOT NULL,
    "storage_path" "text" NOT NULL,
    "compression" "text" DEFAULT 'identity'::"text",
    "mime_type" "text" DEFAULT 'application/json'::"text" NOT NULL,
    "etag" "text",
    "download_count" integer DEFAULT 0,
    "last_downloaded_at" timestamp with time zone,
    CONSTRAINT "catalog_files_byte_size_check" CHECK (("byte_size" > 0))
);


ALTER TABLE "admin"."catalog_files" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."catalog_publish_jobs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "release_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    CONSTRAINT "catalog_publish_jobs_status_check" CHECK (("status" = ANY (ARRAY['PENDING'::"text", 'RUNNING'::"text", 'COMPLETED'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "admin"."catalog_publish_jobs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."catalog_release_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "release_id" "uuid",
    "action" "text" NOT NULL,
    "actor_id" "uuid",
    "timestamp" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "admin"."catalog_release_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."catalog_releases" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "version" bigint NOT NULL,
    "schema_version" integer DEFAULT 2 NOT NULL,
    "minimum_app_version" "text" DEFAULT '1.0.0'::"text" NOT NULL,
    "maximum_app_version" "text",
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "is_current" boolean DEFAULT false NOT NULL,
    "notes" "text",
    "published_by" "uuid",
    "published_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "release_version" "text",
    "package_sha256" "text",
    "record_counts" "jsonb",
    "package_byte_size" integer,
    CONSTRAINT "catalog_releases_schema_version_check" CHECK (("schema_version" > 0)),
    CONSTRAINT "catalog_releases_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'published'::"text", 'archived'::"text"])))
);


ALTER TABLE "admin"."catalog_releases" OWNER TO "postgres";


COMMENT ON COLUMN "admin"."catalog_releases"."release_version" IS 'Semantic release identity, e.g. "1.33.0-alpha" -- distinct from `version` (bare auto-increment) and from `schema_version`. See RELEASE_MANIFEST_SPECIFICATION.md.';



COMMENT ON COLUMN "admin"."catalog_releases"."package_sha256" IS 'SHA-256 of the release artifact as a whole. Distinct from catalog.* row-checksum aggregation (mss_catalog_meta()) -- see HASH_VERIFICATION_SPECIFICATION.md §2.';



COMMENT ON COLUMN "admin"."catalog_releases"."record_counts" IS 'Per-catalog entity counts for this release, mirroring release.json''s recordCounts.';



COMMENT ON COLUMN "admin"."catalog_releases"."package_byte_size" IS 'Byte size of the release artifact (catalog_bundle.json.gz) as published to Supabase Storage.';



ALTER TABLE "admin"."catalog_releases" ALTER COLUMN "version" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "admin"."catalog_releases_version_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "admin"."catalog_validation_runs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completed_at" timestamp with time zone,
    "status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "errors" "jsonb" DEFAULT '[]'::"jsonb",
    "run_by" "uuid",
    CONSTRAINT "catalog_validation_runs_status_check" CHECK (("status" = ANY (ARRAY['PENDING'::"text", 'PASSED'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "admin"."catalog_validation_runs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."event_log" (
    "id" bigint NOT NULL,
    "event_type" "text" NOT NULL,
    "actor_id" "uuid",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "admin"."event_log" OWNER TO "postgres";


ALTER TABLE "admin"."event_log" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "admin"."event_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "admin"."import_batches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "file_name" "text" NOT NULL,
    "batch_status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "records_count" integer DEFAULT 0,
    "errors" "jsonb" DEFAULT '[]'::"jsonb",
    "imported_by" "uuid",
    "imported_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "import_batches_batch_status_check" CHECK (("batch_status" = ANY (ARRAY['PENDING'::"text", 'VALIDATING'::"text", 'PROCESSED'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "admin"."import_batches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."job_queue" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_type" "text" NOT NULL,
    "payload" "jsonb" NOT NULL,
    "status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "error_log" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "job_queue_job_type_check" CHECK (("job_type" = ANY (ARRAY['TRANSLATION'::"text", 'VALIDATION'::"text", 'EMBEDDING'::"text", 'JSON_EXPORT'::"text", 'MANIFEST'::"text", 'CHECKSUMS'::"text"]))),
    CONSTRAINT "job_queue_status_check" CHECK (("status" = ANY (ARRAY['PENDING'::"text", 'RUNNING'::"text", 'COMPLETED'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "admin"."job_queue" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."permissions" (
    "id" smallint NOT NULL,
    "code" "text" NOT NULL,
    "description" "text" NOT NULL
);


ALTER TABLE "admin"."permissions" OWNER TO "postgres";


ALTER TABLE "admin"."permissions" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "admin"."permissions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "admin"."record_locks" (
    "entity_type" "text" NOT NULL,
    "entity_id" "text" NOT NULL,
    "checked_out_by" "uuid" NOT NULL,
    "locked_until" timestamp with time zone NOT NULL
);


ALTER TABLE "admin"."record_locks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."roles" (
    "id" smallint NOT NULL,
    "code" "text" NOT NULL,
    "description" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "roles_code_check" CHECK (("code" ~ '^[a-z][a-z_]{1,31}$'::"text"))
);


ALTER TABLE "admin"."roles" OWNER TO "postgres";


ALTER TABLE "admin"."roles" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "admin"."roles_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "admin"."translation_jobs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "source_lang" "text" DEFAULT 'en'::"text" NOT NULL,
    "target_lang" "text" DEFAULT 'ta'::"text" NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "text" NOT NULL,
    "field_name" "text" NOT NULL,
    "status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "source_text" "text" NOT NULL,
    "translated_text" "text",
    "errors" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "translation_jobs_status_check" CHECK (("status" = ANY (ARRAY['PENDING'::"text", 'PROCESSING'::"text", 'COMPLETED'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "admin"."translation_jobs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "admin"."translation_memory" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "english_text" "text" NOT NULL,
    "tamil_text" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "admin"."translation_memory" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."ai_metadata" (
    "entity_id" "text" NOT NULL,
    "summary_en" "text",
    "summary_ta" "text",
    "keywords" "text"[],
    "embedding_status" "text" DEFAULT 'PENDING'::"text" NOT NULL,
    "generated_at" timestamp with time zone,
    "approved" boolean DEFAULT false,
    CONSTRAINT "ai_metadata_embedding_status_check" CHECK (("embedding_status" = ANY (ARRAY['PENDING'::"text", 'GENERATED'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "catalog"."ai_metadata" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."applicability_matrix" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "government_level" "text",
    "department_authority_id" "text",
    "sector_text" "text",
    "district_text" "text",
    CONSTRAINT "applicability_matrix_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."applicability_matrix" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."authority" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "code" "text",
    "name_en" "text" NOT NULL,
    "name_ta" "text",
    CONSTRAINT "authority_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."authority" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."business_enablement" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "enablement_type" "text",
    "provider_authority_id" "text",
    "online_url" "text",
    CONSTRAINT "business_enablement_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."business_enablement" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."cluster_assistance" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "cluster_name" "text",
    "sector" "text",
    "administering_authority_id" "text",
    CONSTRAINT "cluster_assistance_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."cluster_assistance" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."common" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    CONSTRAINT "common_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."common" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."csr" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "focus_areas" "text"[],
    CONSTRAINT "csr_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."csr" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."enterprise_classification" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "code" "text",
    "dimension" "text",
    "investment_max_inr" numeric(15,2),
    "turnover_max_inr" numeric(15,2),
    CONSTRAINT "enterprise_classification_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."enterprise_classification" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."entity_registry" (
    "entity_id" "text" NOT NULL,
    "entity_type" "text" NOT NULL,
    "catalog_name" "text" NOT NULL,
    "current_version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "validation_status" "text" DEFAULT 'NOT_VALIDATED'::"text" NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "deleted_reason" "text",
    "checksum" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "entity_registry_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"]))),
    CONSTRAINT "entity_registry_validation_status_check" CHECK (("validation_status" = ANY (ARRAY['PASSED'::"text", 'FAILED'::"text", 'WARNING'::"text", 'NOT_VALIDATED'::"text"])))
);


ALTER TABLE "catalog"."entity_registry" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."export" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "target_countries" "text"[],
    CONSTRAINT "export_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."export" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."finance" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "interest_subvention_rate" numeric(5,2),
    "max_loan_amount" numeric(15,2),
    CONSTRAINT "finance_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."finance" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."institution" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "code" "text",
    "name_en" "text" NOT NULL,
    "name_ta" "text",
    "authority_id" "text",
    CONSTRAINT "institution_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."institution" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."knowledge" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "title" "text" NOT NULL,
    "item_type" "text",
    "category" "text",
    CONSTRAINT "knowledge_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."knowledge" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."msme_privilege" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "privilege_type" "text",
    "statute" "text",
    CONSTRAINT "msme_privilege_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."msme_privilege" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."relationships" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "source_type" "text" NOT NULL,
    "source_id" "text" NOT NULL,
    "target_type" "text" NOT NULL,
    "target_id" "text" NOT NULL,
    "relationship_type" "text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "catalog"."relationships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."scheme" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_code" "text",
    "name_en" "text" NOT NULL,
    "name_ta" "text",
    "government_level" "text",
    "scheme_type" "text",
    "state" "text" DEFAULT 'All India'::"text",
    "ministry" "text",
    "department" "text",
    "search_keywords" "text",
    "primary_authority_id" "text",
    "primary_institution_id" "text",
    "minimum_funding_amount" numeric(15,2),
    "maximum_funding_amount" numeric(15,2),
    "is_active" boolean DEFAULT true,
    CONSTRAINT "scheme_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."scheme" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."search_index" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "content" "text" NOT NULL,
    "embedding" "public"."vector"(1536),
    CONSTRAINT "search_index_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."search_index" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."tax" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "exemption_percentage" numeric(5,2),
    CONSTRAINT "tax_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."tax" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "catalog"."treds" (
    "id" "text" NOT NULL,
    "version" "text" NOT NULL,
    "status" "text" DEFAULT 'DRAFT'::"text" NOT NULL,
    "checksum" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "published_at" timestamp with time zone,
    "record_json" "jsonb" NOT NULL,
    "scheme_id" "text",
    "interest_rate_range" "text",
    CONSTRAINT "treds_status_check" CHECK (("status" = ANY (ARRAY['DRAFT'::"text", 'READY_FOR_REVIEW'::"text", 'REVIEWED'::"text", 'APPROVED'::"text", 'PUBLISHED'::"text", 'ARCHIVED'::"text"])))
);


ALTER TABLE "catalog"."treds" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ai_conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ai_conversations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ai_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "conversation_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "ai_messages_role_check" CHECK (("role" = ANY (ARRAY['user'::"text", 'assistant'::"text", 'system'::"text"])))
);


ALTER TABLE "public"."ai_messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."api_rate_limits" (
    "bucket" "text" NOT NULL,
    "identifier" "text" NOT NULL,
    "window_start" timestamp with time zone DEFAULT "now"() NOT NULL,
    "request_count" integer DEFAULT 0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."api_rate_limits" OWNER TO "postgres";


COMMENT ON TABLE "public"."api_rate_limits" IS 'Edge Function rate-limit counters. Written only by service_role via mss_check_rate_limit().';



CREATE TABLE IF NOT EXISTS "public"."audit_log" (
    "id" bigint NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "actor_user_id" "uuid",
    "action" "text" NOT NULL,
    "target_type" "text" NOT NULL,
    "target_id" "text" NOT NULL,
    "request_id" "uuid" NOT NULL,
    "reason" "text",
    "before_revision_id" "uuid",
    "after_revision_id" "uuid",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "audit_log_action_check" CHECK ((("length"("btrim"("action")) >= 3) AND ("length"("btrim"("action")) <= 100))),
    CONSTRAINT "audit_log_metadata_check" CHECK (("jsonb_typeof"("metadata") = 'object'::"text")),
    CONSTRAINT "audit_log_target_id_check" CHECK ((("length"("btrim"("target_id")) >= 1) AND ("length"("btrim"("target_id")) <= 200))),
    CONSTRAINT "audit_log_target_type_check" CHECK ((("length"("btrim"("target_type")) >= 2) AND ("length"("btrim"("target_type")) <= 100)))
);


ALTER TABLE "public"."audit_log" OWNER TO "postgres";


ALTER TABLE "public"."audit_log" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."audit_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."beneficiary_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "beneficiary_categories_code_check" CHECK ((("length"("btrim"("code")) >= 1) AND ("length"("btrim"("code")) <= 64))),
    CONSTRAINT "beneficiary_categories_name_check" CHECK ((("length"("btrim"("name")) >= 2) AND ("length"("btrim"("name")) <= 200)))
);

ALTER TABLE ONLY "public"."beneficiary_categories" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."beneficiary_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bug_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "title" "text" NOT NULL,
    "description" "text" NOT NULL,
    "device_info" "jsonb",
    "status" "text" DEFAULT 'OPEN'::"text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "bug_reports_status_check" CHECK (("status" = ANY (ARRAY['OPEN'::"text", 'IN_PROGRESS'::"text", 'RESOLVED'::"text", 'CLOSED'::"text"])))
);


ALTER TABLE "public"."bug_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chat_logs" (
    "id" bigint NOT NULL,
    "conversation_uid" "text" NOT NULL,
    "turn_index" integer DEFAULT 1 NOT NULL,
    "mode" "text" NOT NULL,
    "user_message" "text" NOT NULL,
    "ai_message" "text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "timezone"('utc'::"text", "now"()) NOT NULL,
    CONSTRAINT "chat_logs_mode_check" CHECK (("mode" = ANY (ARRAY['voice'::"text", 'text'::"text"])))
);


ALTER TABLE "public"."chat_logs" OWNER TO "postgres";


ALTER TABLE "public"."chat_logs" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."chat_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."departments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "departments_code_check" CHECK ((("length"("btrim"("code")) >= 1) AND ("length"("btrim"("code")) <= 64))),
    CONSTRAINT "departments_name_check" CHECK ((("length"("btrim"("name")) >= 2) AND ("length"("btrim"("name")) <= 200)))
);

ALTER TABLE ONLY "public"."departments" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."departments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feature_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "title" "text" NOT NULL,
    "description" "text" NOT NULL,
    "upvotes" integer DEFAULT 0,
    "status" "text" DEFAULT 'UNDER_REVIEW'::"text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "feature_requests_status_check" CHECK (("status" = ANY (ARRAY['UNDER_REVIEW'::"text", 'PLANNED'::"text", 'IN_DEVELOPMENT'::"text", 'COMPLETED'::"text", 'DECLINED'::"text"])))
);


ALTER TABLE "public"."feature_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feedback" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "rating" integer NOT NULL,
    "comment" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "feedback_rating_check" CHECK ((("rating" >= 1) AND ("rating" <= 5)))
);


ALTER TABLE "public"."feedback" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "message" "text" NOT NULL,
    "notification_type" "text",
    "is_read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


COMMENT ON TABLE "public"."notifications" IS 'Stores notifications for users.';



CREATE TABLE IF NOT EXISTS "public"."organization_memberships" (
    "user_id" "uuid" NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "display_name" "text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "organization_memberships_display_name_check" CHECK ((("length"("btrim"("display_name")) >= 2) AND ("length"("btrim"("display_name")) <= 200)))
);

ALTER TABLE ONLY "public"."organization_memberships" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."organization_memberships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."organizations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "organizations_code_check" CHECK (("code" ~ '^[A-Z0-9][A-Z0-9_-]{1,31}$'::"text")),
    CONSTRAINT "organizations_name_check" CHECK ((("length"("btrim"("name")) >= 2) AND ("length"("btrim"("name")) <= 200)))
);

ALTER TABLE ONLY "public"."organizations" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."organizations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "name" "text",
    "photo_url" "text",
    "language" character varying(10) DEFAULT 'en'::character varying,
    "navigation_mode" character varying(20) DEFAULT 'regular'::character varying,
    "applicant_type" "text",
    "state" "text",
    "district" "text",
    "pincode" character varying(10),
    "is_profile_complete" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "last_login_at" timestamp with time zone DEFAULT "now"(),
    "dob" "date",
    "gender" character varying(50),
    "disability" character varying(100),
    "veteran" boolean DEFAULT false,
    "house" "text",
    "street" "text",
    "area" "text",
    "village" "text",
    "city" "text",
    "qualification" "text",
    "annual_income" numeric(15,2) DEFAULT 0.0,
    "community" character varying(100),
    "notifications" boolean DEFAULT true,
    "theme" character varying(20) DEFAULT 'light'::character varying,
    "phone" character varying(20),
    "religion" "text",
    "first_gen_graduate" boolean DEFAULT false NOT NULL
);

ALTER TABLE ONLY "public"."profiles" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON COLUMN "public"."profiles"."religion" IS 'Self-reported religion, used for minority-category scheme matching (RecommendationEngine). Free text from the onboarding wizard, not a constrained enum.';



COMMENT ON COLUMN "public"."profiles"."first_gen_graduate" IS 'Whether the user is a first-generation graduate, used for NEEDS-scheme recommendation scoring.';



CREATE TABLE IF NOT EXISTS "public"."promo_alerts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "badge_text" "text" NOT NULL,
    "badge_text_color" "text" DEFAULT '#EA580C'::"text",
    "badge_bg_color" "text" DEFAULT '#FFF7ED'::"text",
    "bg_gradient_start" "text" DEFAULT '#FFF7ED'::"text",
    "bg_gradient_end" "text" DEFAULT '#FFFFEDD5'::"text",
    "btn_text" "text" DEFAULT 'View Details'::"text",
    "btn_color" "text" DEFAULT '#EA580C'::"text",
    "target_route" "text" DEFAULT 'notifications'::"text",
    "graphic_type" "text" DEFAULT 'calendar'::"text",
    "target_gender" "text",
    "target_state" "text",
    "target_community" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."promo_alerts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."question_options" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "question_id" "uuid" NOT NULL,
    "option_label" "text" NOT NULL,
    "option_value" "text" NOT NULL,
    "next_question_id" "uuid",
    "display_order" integer DEFAULT 1,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."question_options" OWNER TO "postgres";


COMMENT ON TABLE "public"."question_options" IS 'Options available for select-type questions.';



CREATE TABLE IF NOT EXISTS "public"."questionnaire_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "startup_profile_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'IN_PROGRESS'::"text",
    "completed_percentage" numeric(5,2) DEFAULT 0,
    "started_at" timestamp with time zone DEFAULT "now"(),
    "completed_at" timestamp with time zone
);


ALTER TABLE "public"."questionnaire_sessions" OWNER TO "postgres";


COMMENT ON TABLE "public"."questionnaire_sessions" IS 'Tracks questionnaire progress for a startup profile.';



CREATE TABLE IF NOT EXISTS "public"."questions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "question_text" "text" NOT NULL,
    "description" "text",
    "field_name" "text" NOT NULL,
    "input_type" "text" NOT NULL,
    "is_required" boolean DEFAULT true,
    "display_order" integer DEFAULT 1,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."questions" OWNER TO "postgres";


COMMENT ON TABLE "public"."questions" IS 'Master list of questionnaire questions.';



CREATE TABLE IF NOT EXISTS "public"."recent_schemes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "scheme_id" "text" NOT NULL,
    "viewed_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."recent_schemes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recommendations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "startup_profile_id" "uuid" NOT NULL,
    "scheme_id" "uuid" NOT NULL,
    "match_score" numeric(5,2) NOT NULL,
    "recommendation_rank" integer NOT NULL,
    "recommendation_reason" "text",
    "generated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."recommendations" OWNER TO "postgres";


COMMENT ON TABLE "public"."recommendations" IS 'Stores generated scheme recommendations for each startup profile.';



CREATE TABLE IF NOT EXISTS "public"."regions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "level" "public"."region_level" NOT NULL,
    "parent_id" "uuid",
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "regions_check" CHECK ((("parent_id" IS NULL) OR ("parent_id" <> "id"))),
    CONSTRAINT "regions_code_check" CHECK ((("length"("btrim"("code")) >= 1) AND ("length"("btrim"("code")) <= 64))),
    CONSTRAINT "regions_name_check" CHECK ((("length"("btrim"("name")) >= 1) AND ("length"("btrim"("name")) <= 200)))
);

ALTER TABLE ONLY "public"."regions" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."regions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" smallint NOT NULL,
    "code" "text" NOT NULL,
    "description" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "roles_code_check" CHECK (("code" ~ '^[a-z][a-z_]{1,31}$'::"text"))
);

ALTER TABLE ONLY "public"."roles" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."roles" OWNER TO "postgres";


ALTER TABLE "public"."roles" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."roles_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."saved_schemes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "scheme_id" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."saved_schemes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."search_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "query" "text" NOT NULL,
    "results_count" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."search_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."startup_profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "profile_name" "text" NOT NULL,
    "description" "text",
    "industry" "text" NOT NULL,
    "applicant_type" "text" NOT NULL,
    "business_stage" "text" NOT NULL,
    "business_registered" boolean DEFAULT false NOT NULL,
    "funding_required_amount" numeric(15,2),
    "funding_purpose" "text",
    "is_first_generation_entrepreneur" boolean DEFAULT false NOT NULL,
    "is_active" boolean DEFAULT false NOT NULL,
    "last_used_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "registration_numbers" "text",
    CONSTRAINT "chk_business_stage" CHECK (("business_stage" = ANY (ARRAY['Idea'::"text", 'Prototype'::"text", 'Registered'::"text", 'Operational'::"text", 'Expansion'::"text"]))),
    CONSTRAINT "chk_funding_amount" CHECK ((("funding_required_amount" IS NULL) OR ("funding_required_amount" >= (0)::numeric)))
);

ALTER TABLE ONLY "public"."startup_profiles" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."startup_profiles" OWNER TO "postgres";


COMMENT ON TABLE "public"."startup_profiles" IS 'Stores multiple startup ideas created by an entrepreneur.';



COMMENT ON COLUMN "public"."startup_profiles"."profile_name" IS 'Friendly name of the startup idea. Example: AI Startup';



COMMENT ON COLUMN "public"."startup_profiles"."industry" IS 'Technology, Agriculture, Manufacturing, Healthcare, etc.';



COMMENT ON COLUMN "public"."startup_profiles"."applicant_type" IS 'Student, Woman Entrepreneur, SHG, Farmer, Artisan, MSME, etc.';



COMMENT ON COLUMN "public"."startup_profiles"."business_stage" IS 'Current stage of the startup.';



COMMENT ON COLUMN "public"."startup_profiles"."funding_required_amount" IS 'Estimated funding required for the startup.';



CREATE TABLE IF NOT EXISTS "public"."sync_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "device_id" "text",
    "platform" "text",
    "previous_release_version" bigint,
    "synced_release_version" bigint NOT NULL,
    "status" "text" NOT NULL,
    "error_message" "text",
    "duration_ms" integer,
    "synced_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sync_history_status_check" CHECK (("status" = ANY (ARRAY['SUCCESS'::"text", 'FAILED'::"text"])))
);


ALTER TABLE "public"."sync_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_memory" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "key" "text" NOT NULL,
    "value" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_memory" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_regions" (
    "user_id" "uuid" NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "region_id" "uuid" NOT NULL,
    "assigned_by" "uuid",
    "assigned_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE ONLY "public"."user_regions" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_regions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_responses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "question_id" "uuid" NOT NULL,
    "answer" "text",
    "answered_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_responses" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_responses" IS 'Stores answers given during questionnaire.';



CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "user_id" "uuid" NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "role_id" smallint NOT NULL,
    "granted_by" "uuid",
    "granted_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE ONLY "public"."user_roles" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


ALTER TABLE ONLY "admin"."admins"
    ADD CONSTRAINT "admins_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."catalog_change_log"
    ADD CONSTRAINT "catalog_change_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."catalog_files"
    ADD CONSTRAINT "catalog_files_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."catalog_publish_jobs"
    ADD CONSTRAINT "catalog_publish_jobs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."catalog_release_history"
    ADD CONSTRAINT "catalog_release_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."catalog_releases"
    ADD CONSTRAINT "catalog_releases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."catalog_releases"
    ADD CONSTRAINT "catalog_releases_version_key" UNIQUE ("version");



ALTER TABLE ONLY "admin"."catalog_validation_runs"
    ADD CONSTRAINT "catalog_validation_runs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."event_log"
    ADD CONSTRAINT "event_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."import_batches"
    ADD CONSTRAINT "import_batches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."job_queue"
    ADD CONSTRAINT "job_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."permissions"
    ADD CONSTRAINT "permissions_code_key" UNIQUE ("code");



ALTER TABLE ONLY "admin"."permissions"
    ADD CONSTRAINT "permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."record_locks"
    ADD CONSTRAINT "record_locks_pkey" PRIMARY KEY ("entity_type", "entity_id");



ALTER TABLE ONLY "admin"."roles"
    ADD CONSTRAINT "roles_code_key" UNIQUE ("code");



ALTER TABLE ONLY "admin"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."translation_jobs"
    ADD CONSTRAINT "translation_jobs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "admin"."translation_memory"
    ADD CONSTRAINT "translation_memory_english_text_key" UNIQUE ("english_text");



ALTER TABLE ONLY "admin"."translation_memory"
    ADD CONSTRAINT "translation_memory_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."ai_metadata"
    ADD CONSTRAINT "ai_metadata_pkey" PRIMARY KEY ("entity_id");



ALTER TABLE ONLY "catalog"."applicability_matrix"
    ADD CONSTRAINT "applicability_matrix_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."authority"
    ADD CONSTRAINT "authority_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."business_enablement"
    ADD CONSTRAINT "business_enablement_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."cluster_assistance"
    ADD CONSTRAINT "cluster_assistance_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."common"
    ADD CONSTRAINT "common_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."csr"
    ADD CONSTRAINT "csr_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."enterprise_classification"
    ADD CONSTRAINT "enterprise_classification_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."entity_registry"
    ADD CONSTRAINT "entity_registry_pkey" PRIMARY KEY ("entity_id");



ALTER TABLE ONLY "catalog"."export"
    ADD CONSTRAINT "export_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."finance"
    ADD CONSTRAINT "finance_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."institution"
    ADD CONSTRAINT "institution_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."knowledge"
    ADD CONSTRAINT "knowledge_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."msme_privilege"
    ADD CONSTRAINT "msme_privilege_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."relationships"
    ADD CONSTRAINT "relationships_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."scheme"
    ADD CONSTRAINT "scheme_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."scheme"
    ADD CONSTRAINT "scheme_scheme_code_key" UNIQUE ("scheme_code");



ALTER TABLE ONLY "catalog"."search_index"
    ADD CONSTRAINT "search_index_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."tax"
    ADD CONSTRAINT "tax_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "catalog"."treds"
    ADD CONSTRAINT "treds_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ai_conversations"
    ADD CONSTRAINT "ai_conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ai_messages"
    ADD CONSTRAINT "ai_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."api_rate_limits"
    ADD CONSTRAINT "api_rate_limits_pkey" PRIMARY KEY ("bucket", "identifier");



ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."beneficiary_categories"
    ADD CONSTRAINT "beneficiary_categories_organization_id_code_key" UNIQUE ("organization_id", "code");



ALTER TABLE ONLY "public"."beneficiary_categories"
    ADD CONSTRAINT "beneficiary_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bug_reports"
    ADD CONSTRAINT "bug_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chat_logs"
    ADD CONSTRAINT "chat_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_organization_id_code_key" UNIQUE ("organization_id", "code");



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feature_requests"
    ADD CONSTRAINT "feature_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."organization_memberships"
    ADD CONSTRAINT "organization_memberships_pkey" PRIMARY KEY ("user_id", "organization_id");



ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."promo_alerts"
    ADD CONSTRAINT "promo_alerts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."question_options"
    ADD CONSTRAINT "question_options_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."questionnaire_sessions"
    ADD CONSTRAINT "questionnaire_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."questions"
    ADD CONSTRAINT "questions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recent_schemes"
    ADD CONSTRAINT "recent_schemes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recommendations"
    ADD CONSTRAINT "recommendations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recommendations"
    ADD CONSTRAINT "recommendations_startup_profile_id_scheme_id_key" UNIQUE ("startup_profile_id", "scheme_id");



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_id_organization_id_key" UNIQUE ("id", "organization_id");



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_organization_id_code_key" UNIQUE ("organization_id", "code");



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."saved_schemes"
    ADD CONSTRAINT "saved_schemes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."saved_schemes"
    ADD CONSTRAINT "saved_schemes_user_id_scheme_id_key" UNIQUE ("user_id", "scheme_id");



ALTER TABLE ONLY "public"."search_logs"
    ADD CONSTRAINT "search_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."startup_profiles"
    ADD CONSTRAINT "startup_profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sync_history"
    ADD CONSTRAINT "sync_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_memory"
    ADD CONSTRAINT "user_memory_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_memory"
    ADD CONSTRAINT "user_memory_user_id_key_key" UNIQUE ("user_id", "key");



ALTER TABLE ONLY "public"."user_regions"
    ADD CONSTRAINT "user_regions_pkey" PRIMARY KEY ("user_id", "region_id");



ALTER TABLE ONLY "public"."user_responses"
    ADD CONSTRAINT "user_responses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_responses"
    ADD CONSTRAINT "user_responses_session_id_question_id_key" UNIQUE ("session_id", "question_id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("user_id", "organization_id", "role_id");



CREATE INDEX "admin_catalog_releases_one_current_idx" ON "admin"."catalog_releases" USING "btree" ("is_current") WHERE "is_current";



CREATE INDEX "admin_translation_mem_en_idx" ON "admin"."translation_memory" USING "btree" ("english_text");



CREATE INDEX "catalog_applicability_matrix_scheme_idx" ON "catalog"."applicability_matrix" USING "btree" ("scheme_id");



CREATE INDEX "catalog_relationships_src_idx" ON "catalog"."relationships" USING "btree" ("source_type", "source_id");



CREATE INDEX "catalog_relationships_tgt_idx" ON "catalog"."relationships" USING "btree" ("target_type", "target_id");



CREATE INDEX "catalog_scheme_filter_idx" ON "catalog"."scheme" USING "btree" ("government_level", "state", "scheme_type");



CREATE INDEX "catalog_scheme_name_en_idx" ON "catalog"."scheme" USING "btree" ("name_en");



CREATE INDEX "catalog_scheme_name_ta_idx" ON "catalog"."scheme" USING "btree" ("name_ta");



CREATE INDEX "catalog_scheme_search_idx" ON "catalog"."scheme" USING "gin" ("to_tsvector"('"english"'::"regconfig", (("name_en" || ' '::"text") || COALESCE("search_keywords", ''::"text"))));



CREATE INDEX "catalog_search_index_vector_idx" ON "catalog"."search_index" USING "hnsw" ("embedding" "public"."vector_cosine_ops");



CREATE INDEX "api_rate_limits_updated_at_idx" ON "public"."api_rate_limits" USING "btree" ("updated_at");



CREATE INDEX "audit_log_organization_created_idx" ON "public"."audit_log" USING "btree" ("organization_id", "created_at" DESC);



CREATE INDEX "audit_log_request_id_idx" ON "public"."audit_log" USING "btree" ("request_id");



CREATE INDEX "audit_log_target_idx" ON "public"."audit_log" USING "btree" ("organization_id", "target_type", "target_id", "created_at" DESC);



CREATE INDEX "idx_chat_logs_conversation_uid" ON "public"."chat_logs" USING "btree" ("conversation_uid");



CREATE INDEX "idx_chat_logs_created_at" ON "public"."chat_logs" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_notifications_user" ON "public"."notifications" USING "btree" ("user_id");



CREATE INDEX "idx_question_options_question" ON "public"."question_options" USING "btree" ("question_id");



CREATE INDEX "idx_recommendations_profile" ON "public"."recommendations" USING "btree" ("startup_profile_id");



CREATE INDEX "idx_recommendations_score" ON "public"."recommendations" USING "btree" ("match_score" DESC);



CREATE INDEX "idx_startup_profiles_active" ON "public"."startup_profiles" USING "btree" ("is_active");



CREATE INDEX "idx_startup_profiles_user" ON "public"."startup_profiles" USING "btree" ("user_id");



CREATE INDEX "idx_user_responses_session" ON "public"."user_responses" USING "btree" ("session_id");



CREATE INDEX "regions_organization_level_idx" ON "public"."regions" USING "btree" ("organization_id", "level") WHERE "active";



CREATE INDEX "regions_parent_idx" ON "public"."regions" USING "btree" ("parent_id");



CREATE INDEX "user_regions_user_organization_idx" ON "public"."user_regions" USING "btree" ("user_id", "organization_id");



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."applicability_matrix" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."authority" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."business_enablement" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."cluster_assistance" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."common" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."csr" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."enterprise_classification" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."export" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."finance" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."institution" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."knowledge" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."msme_privilege" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."scheme" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."search_index" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."tax" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "trg_recompute_checksum" BEFORE INSERT OR UPDATE ON "catalog"."treds" FOR EACH ROW EXECUTE FUNCTION "catalog"."mss_recompute_row_checksum"();



CREATE OR REPLACE TRIGGER "audit_log_prevent_update_delete" BEFORE DELETE OR UPDATE ON "public"."audit_log" FOR EACH ROW EXECUTE FUNCTION "private"."prevent_audit_mutation"();



CREATE OR REPLACE TRIGGER "beneficiary_categories_set_updated_at" BEFORE UPDATE ON "public"."beneficiary_categories" FOR EACH ROW EXECUTE FUNCTION "private"."set_updated_at"();



CREATE OR REPLACE TRIGGER "departments_set_updated_at" BEFORE UPDATE ON "public"."departments" FOR EACH ROW EXECUTE FUNCTION "private"."set_updated_at"();



CREATE OR REPLACE TRIGGER "organization_memberships_set_updated_at" BEFORE UPDATE ON "public"."organization_memberships" FOR EACH ROW EXECUTE FUNCTION "private"."set_updated_at"();



CREATE OR REPLACE TRIGGER "organizations_set_updated_at" BEFORE UPDATE ON "public"."organizations" FOR EACH ROW EXECUTE FUNCTION "private"."set_updated_at"();



CREATE OR REPLACE TRIGGER "regions_set_updated_at" BEFORE UPDATE ON "public"."regions" FOR EACH ROW EXECUTE FUNCTION "private"."set_updated_at"();



ALTER TABLE ONLY "admin"."admins"
    ADD CONSTRAINT "admins_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "admin"."admins"
    ADD CONSTRAINT "admins_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "admin"."roles"("id");



ALTER TABLE ONLY "admin"."catalog_change_log"
    ADD CONSTRAINT "catalog_change_log_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."catalog_change_log"
    ADD CONSTRAINT "catalog_change_log_changed_by_fkey" FOREIGN KEY ("changed_by") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."catalog_files"
    ADD CONSTRAINT "catalog_files_release_id_fkey" FOREIGN KEY ("release_id") REFERENCES "admin"."catalog_releases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "admin"."catalog_publish_jobs"
    ADD CONSTRAINT "catalog_publish_jobs_release_id_fkey" FOREIGN KEY ("release_id") REFERENCES "admin"."catalog_releases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "admin"."catalog_release_history"
    ADD CONSTRAINT "catalog_release_history_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."catalog_release_history"
    ADD CONSTRAINT "catalog_release_history_release_id_fkey" FOREIGN KEY ("release_id") REFERENCES "admin"."catalog_releases"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "admin"."catalog_releases"
    ADD CONSTRAINT "catalog_releases_published_by_fkey" FOREIGN KEY ("published_by") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."catalog_validation_runs"
    ADD CONSTRAINT "catalog_validation_runs_run_by_fkey" FOREIGN KEY ("run_by") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."event_log"
    ADD CONSTRAINT "event_log_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."import_batches"
    ADD CONSTRAINT "import_batches_imported_by_fkey" FOREIGN KEY ("imported_by") REFERENCES "admin"."admins"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "admin"."record_locks"
    ADD CONSTRAINT "record_locks_checked_out_by_fkey" FOREIGN KEY ("checked_out_by") REFERENCES "admin"."admins"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "catalog"."ai_metadata"
    ADD CONSTRAINT "ai_metadata_entity_id_fkey" FOREIGN KEY ("entity_id") REFERENCES "catalog"."entity_registry"("entity_id") ON DELETE CASCADE;



ALTER TABLE ONLY "catalog"."applicability_matrix"
    ADD CONSTRAINT "applicability_matrix_department_authority_id_fkey" FOREIGN KEY ("department_authority_id") REFERENCES "catalog"."authority"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "catalog"."applicability_matrix"
    ADD CONSTRAINT "applicability_matrix_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "catalog"."business_enablement"
    ADD CONSTRAINT "business_enablement_provider_authority_id_fkey" FOREIGN KEY ("provider_authority_id") REFERENCES "catalog"."authority"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "catalog"."cluster_assistance"
    ADD CONSTRAINT "cluster_assistance_administering_authority_id_fkey" FOREIGN KEY ("administering_authority_id") REFERENCES "catalog"."authority"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "catalog"."csr"
    ADD CONSTRAINT "csr_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "catalog"."export"
    ADD CONSTRAINT "export_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "catalog"."finance"
    ADD CONSTRAINT "finance_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "catalog"."institution"
    ADD CONSTRAINT "institution_authority_id_fkey" FOREIGN KEY ("authority_id") REFERENCES "catalog"."authority"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "catalog"."search_index"
    ADD CONSTRAINT "search_index_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "catalog"."tax"
    ADD CONSTRAINT "tax_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "catalog"."treds"
    ADD CONSTRAINT "treds_scheme_id_fkey" FOREIGN KEY ("scheme_id") REFERENCES "catalog"."scheme"("id") ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "public"."ai_conversations"
    ADD CONSTRAINT "ai_conversations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ai_messages"
    ADD CONSTRAINT "ai_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."ai_conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_actor_user_id_fkey" FOREIGN KEY ("actor_user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."audit_log"
    ADD CONSTRAINT "audit_log_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."beneficiary_categories"
    ADD CONSTRAINT "beneficiary_categories_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."bug_reports"
    ADD CONSTRAINT "bug_reports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."departments"
    ADD CONSTRAINT "departments_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."feature_requests"
    ADD CONSTRAINT "feature_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."feedback"
    ADD CONSTRAINT "feedback_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."organization_memberships"
    ADD CONSTRAINT "organization_memberships_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."organization_memberships"
    ADD CONSTRAINT "organization_memberships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."question_options"
    ADD CONSTRAINT "question_options_next_question_id_fkey" FOREIGN KEY ("next_question_id") REFERENCES "public"."questions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."question_options"
    ADD CONSTRAINT "question_options_question_id_fkey" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."questionnaire_sessions"
    ADD CONSTRAINT "questionnaire_sessions_startup_profile_id_fkey" FOREIGN KEY ("startup_profile_id") REFERENCES "public"."startup_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recent_schemes"
    ADD CONSTRAINT "recent_schemes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recommendations"
    ADD CONSTRAINT "recommendations_startup_profile_id_fkey" FOREIGN KEY ("startup_profile_id") REFERENCES "public"."startup_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_parent_id_organization_id_fkey" FOREIGN KEY ("parent_id", "organization_id") REFERENCES "public"."regions"("id", "organization_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."saved_schemes"
    ADD CONSTRAINT "saved_schemes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."search_logs"
    ADD CONSTRAINT "search_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."startup_profiles"
    ADD CONSTRAINT "startup_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sync_history"
    ADD CONSTRAINT "sync_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_memory"
    ADD CONSTRAINT "user_memory_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_regions"
    ADD CONSTRAINT "user_regions_assigned_by_fkey" FOREIGN KEY ("assigned_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_regions"
    ADD CONSTRAINT "user_regions_region_id_organization_id_fkey" FOREIGN KEY ("region_id", "organization_id") REFERENCES "public"."regions"("id", "organization_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_regions"
    ADD CONSTRAINT "user_regions_user_id_organization_id_fkey" FOREIGN KEY ("user_id", "organization_id") REFERENCES "public"."organization_memberships"("user_id", "organization_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_responses"
    ADD CONSTRAINT "user_responses_question_id_fkey" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_responses"
    ADD CONSTRAINT "user_responses_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."questionnaire_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_granted_by_fkey" FOREIGN KEY ("granted_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_organization_id_fkey" FOREIGN KEY ("user_id", "organization_id") REFERENCES "public"."organization_memberships"("user_id", "organization_id") ON DELETE CASCADE;



CREATE POLICY "Admins manage admin permissions" ON "admin"."permissions" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Admins manage admin roles" ON "admin"."roles" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Admins manage admins list" ON "admin"."admins" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Staff manage catalog change logs" ON "admin"."catalog_change_log" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage catalog files" ON "admin"."catalog_files" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage catalog release history" ON "admin"."catalog_release_history" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage catalog releases" ON "admin"."catalog_releases" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage import batches" ON "admin"."import_batches" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage job queue" ON "admin"."job_queue" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage locks" ON "admin"."record_locks" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage publish jobs" ON "admin"."catalog_publish_jobs" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff manage translation jobs" ON "admin"."translation_jobs" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Staff manage translation memory" ON "admin"."translation_memory" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Staff manage validation runs" ON "admin"."catalog_validation_runs" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text", 'publisher'::"text"]));



CREATE POLICY "Staff view event logs" ON "admin"."event_log" FOR SELECT TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'auditor'::"text"]));



ALTER TABLE "admin"."admins" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."catalog_change_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."catalog_files" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."catalog_publish_jobs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."catalog_release_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."catalog_releases" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."catalog_validation_runs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."event_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."import_batches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."job_queue" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."record_locks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."translation_jobs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "admin"."translation_memory" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Admins manage applicability_matrix" ON "catalog"."applicability_matrix" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins manage business_enablement" ON "catalog"."business_enablement" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins manage cluster_assistance" ON "catalog"."cluster_assistance" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins manage enterprise_classification" ON "catalog"."enterprise_classification" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins manage msme_privilege" ON "catalog"."msme_privilege" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage ai_metadata" ON "catalog"."ai_metadata" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage authority" ON "catalog"."authority" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage catalog registry" ON "catalog"."entity_registry" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage common" ON "catalog"."common" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage csr" ON "catalog"."csr" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage export" ON "catalog"."export" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage finance" ON "catalog"."finance" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage institution" ON "catalog"."institution" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage knowledge" ON "catalog"."knowledge" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage relationships" ON "catalog"."relationships" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage scheme" ON "catalog"."scheme" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage search_index" ON "catalog"."search_index" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage tax" ON "catalog"."tax" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Admins/Editors manage treds" ON "catalog"."treds" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text", 'content_editor'::"text"]));



CREATE POLICY "Anon/Public read ai_metadata" ON "catalog"."ai_metadata" FOR SELECT TO "authenticated", "anon" USING (("approved" = true));



CREATE POLICY "Anon/Public read authority" ON "catalog"."authority" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read catalog registry" ON "catalog"."entity_registry" FOR SELECT TO "authenticated", "anon" USING ((("status" = 'PUBLISHED'::"text") AND ("is_deleted" = false)));



CREATE POLICY "Anon/Public read common" ON "catalog"."common" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read csr" ON "catalog"."csr" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read export" ON "catalog"."export" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read finance" ON "catalog"."finance" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read institution" ON "catalog"."institution" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read knowledge" ON "catalog"."knowledge" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read scheme" ON "catalog"."scheme" FOR SELECT TO "authenticated", "anon" USING ((("is_active" = true) AND ("status" = 'PUBLISHED'::"text")));



CREATE POLICY "Anon/Public read search_index" ON "catalog"."search_index" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read tax" ON "catalog"."tax" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Anon/Public read treds" ON "catalog"."treds" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Public read published applicability_matrix" ON "catalog"."applicability_matrix" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Public read published business_enablement" ON "catalog"."business_enablement" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Public read published cluster_assistance" ON "catalog"."cluster_assistance" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Public read published enterprise_classification" ON "catalog"."enterprise_classification" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Public read published msme_privilege" ON "catalog"."msme_privilege" FOR SELECT TO "authenticated", "anon" USING (("status" = 'PUBLISHED'::"text"));



CREATE POLICY "Public read relationships for published entities" ON "catalog"."relationships" FOR SELECT TO "authenticated", "anon" USING ((EXISTS ( SELECT 1
   FROM "catalog"."entity_registry" "er"
  WHERE (("er"."entity_id" = "relationships"."source_id") AND ("er"."status" = 'PUBLISHED'::"text") AND ("er"."is_deleted" = false)))));



ALTER TABLE "catalog"."ai_metadata" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."applicability_matrix" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."authority" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."business_enablement" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."cluster_assistance" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."common" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."csr" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."enterprise_classification" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."entity_registry" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."export" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."finance" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."institution" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."knowledge" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."msme_privilege" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."relationships" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."scheme" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."search_index" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."tax" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "catalog"."treds" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Admins manage all bug reports" ON "public"."bug_reports" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Admins manage feature requests" ON "public"."feature_requests" TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Admins read feedback" ON "public"."feedback" FOR SELECT TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Admins read search logs" ON "public"."search_logs" FOR SELECT TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Admins read sync history" ON "public"."sync_history" FOR SELECT TO "authenticated" USING ("private"."has_admin_role"("auth"."uid"(), ARRAY['administrator'::"text"]));



CREATE POLICY "Authenticated read feature requests" ON "public"."feature_requests" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Authenticated read promo_alerts" ON "public"."promo_alerts" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Profiles delete access" ON "public"."profiles" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "Profiles insert access" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Profiles select access" ON "public"."profiles" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));



CREATE POLICY "Profiles update access" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Public can view question options" ON "public"."question_options" FOR SELECT USING (true);



CREATE POLICY "Public can view questions" ON "public"."questions" FOR SELECT USING (true);



CREATE POLICY "Users create feedback" ON "public"."feedback" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users create search logs" ON "public"."search_logs" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users create sync history" ON "public"."sync_history" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users create/upvote feature requests" ON "public"."feature_requests" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own ai conversations" ON "public"."ai_conversations" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own ai messages" ON "public"."ai_messages" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."ai_conversations" "c"
  WHERE (("c"."id" = "ai_messages"."conversation_id") AND ("c"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."ai_conversations" "c"
  WHERE (("c"."id" = "ai_messages"."conversation_id") AND ("c"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage own bug reports" ON "public"."bug_reports" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own notifications" ON "public"."notifications" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own questionnaire sessions" ON "public"."questionnaire_sessions" USING (("startup_profile_id" IN ( SELECT "startup_profiles"."id"
   FROM "public"."startup_profiles"
  WHERE ("startup_profiles"."user_id" = "auth"."uid"())))) WITH CHECK (("startup_profile_id" IN ( SELECT "startup_profiles"."id"
   FROM "public"."startup_profiles"
  WHERE ("startup_profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users manage own recent schemes" ON "public"."recent_schemes" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own responses" ON "public"."user_responses" USING ((EXISTS ( SELECT 1
   FROM ("public"."questionnaire_sessions" "qs"
     JOIN "public"."startup_profiles" "sp" ON (("qs"."startup_profile_id" = "sp"."id")))
  WHERE (("qs"."id" = "user_responses"."session_id") AND ("sp"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."questionnaire_sessions" "qs"
     JOIN "public"."startup_profiles" "sp" ON (("qs"."startup_profile_id" = "sp"."id")))
  WHERE (("qs"."id" = "user_responses"."session_id") AND ("sp"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage own saved schemes" ON "public"."saved_schemes" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own startup profile" ON "public"."startup_profiles" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users manage own user memory" ON "public"."user_memory" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users view own recommendations" ON "public"."recommendations" USING (("startup_profile_id" IN ( SELECT "startup_profiles"."id"
   FROM "public"."startup_profiles"
  WHERE ("startup_profiles"."user_id" = "auth"."uid"())))) WITH CHECK (("startup_profile_id" IN ( SELECT "startup_profiles"."id"
   FROM "public"."startup_profiles"
  WHERE ("startup_profiles"."user_id" = "auth"."uid"()))));



ALTER TABLE "public"."ai_conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ai_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."api_rate_limits" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."audit_log" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audit_log_read_oversight" ON "public"."audit_log" FOR SELECT TO "authenticated" USING ("private"."has_role"("organization_id", ARRAY['administrator'::"text", 'auditor'::"text"]));



ALTER TABLE "public"."beneficiary_categories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "beneficiary_categories_manage_administrators" ON "public"."beneficiary_categories" TO "authenticated" USING ("private"."has_role"("organization_id", ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_role"("organization_id", ARRAY['administrator'::"text"]));



CREATE POLICY "beneficiary_categories_read_members" ON "public"."beneficiary_categories" FOR SELECT TO "authenticated" USING ("private"."belongs_to_organization"("organization_id"));



ALTER TABLE "public"."bug_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chat_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "chat_logs client insert" ON "public"."chat_logs" FOR INSERT TO "authenticated" WITH CHECK (true);



ALTER TABLE "public"."departments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "departments_manage_administrators" ON "public"."departments" TO "authenticated" USING ("private"."has_role"("organization_id", ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_role"("organization_id", ARRAY['administrator'::"text"]));



CREATE POLICY "departments_read_members" ON "public"."departments" FOR SELECT TO "authenticated" USING ("private"."belongs_to_organization"("organization_id"));



ALTER TABLE "public"."feature_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."feedback" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."organization_memberships" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "organization_memberships_manage_administrators" ON "public"."organization_memberships" TO "authenticated" USING ("private"."has_role"("organization_id", ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_role"("organization_id", ARRAY['administrator'::"text"]));



CREATE POLICY "organization_memberships_read_self_or_oversight" ON "public"."organization_memberships" FOR SELECT TO "authenticated" USING ((("user_id" = "auth"."uid"()) OR "private"."has_role"("organization_id", ARRAY['administrator'::"text", 'auditor'::"text"])));



ALTER TABLE "public"."organizations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "organizations_read_members" ON "public"."organizations" FOR SELECT TO "authenticated" USING ("private"."belongs_to_organization"("id"));



CREATE POLICY "organizations_update_administrators" ON "public"."organizations" FOR UPDATE TO "authenticated" USING ("private"."has_role"("id", ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_role"("id", ARRAY['administrator'::"text"]));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."promo_alerts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."question_options" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."questionnaire_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."questions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recent_schemes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recommendations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."regions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "regions_manage_administrators" ON "public"."regions" TO "authenticated" USING ("private"."has_role"("organization_id", ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_role"("organization_id", ARRAY['administrator'::"text"]));



CREATE POLICY "regions_read_members" ON "public"."regions" FOR SELECT TO "authenticated" USING ("private"."belongs_to_organization"("organization_id"));



ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "roles_read_authenticated" ON "public"."roles" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."saved_schemes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."search_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."startup_profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sync_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_memory" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_regions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_regions_manage_administrators" ON "public"."user_regions" TO "authenticated" USING ("private"."has_role"("organization_id", ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_role"("organization_id", ARRAY['administrator'::"text"]));



CREATE POLICY "user_regions_read_self_or_oversight" ON "public"."user_regions" FOR SELECT TO "authenticated" USING ((("user_id" = "auth"."uid"()) OR "private"."has_role"("organization_id", ARRAY['administrator'::"text", 'auditor'::"text"])));



ALTER TABLE "public"."user_responses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_roles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_roles_manage_administrators" ON "public"."user_roles" TO "authenticated" USING ("private"."has_role"("organization_id", ARRAY['administrator'::"text"])) WITH CHECK ("private"."has_role"("organization_id", ARRAY['administrator'::"text"]));



CREATE POLICY "user_roles_read_self_or_oversight" ON "public"."user_roles" FOR SELECT TO "authenticated" USING ((("user_id" = "auth"."uid"()) OR "private"."has_role"("organization_id", ARRAY['administrator'::"text", 'auditor'::"text"])));



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "catalog"."mss_search"("q" "text", "lang" "text", "types" "text"[], "lim" integer, "off" integer) TO "anon";
GRANT ALL ON FUNCTION "catalog"."mss_search"("q" "text", "lang" "text", "types" "text"[], "lim" integer, "off" integer) TO "authenticated";



GRANT ALL ON FUNCTION "graphql_public"."graphql"("operationName" "text", "query" "text", "variables" "jsonb", "extensions" "jsonb") TO "postgres";
GRANT ALL ON FUNCTION "graphql_public"."graphql"("operationName" "text", "query" "text", "variables" "jsonb", "extensions" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "graphql_public"."graphql"("operationName" "text", "query" "text", "variables" "jsonb", "extensions" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "graphql_public"."graphql"("operationName" "text", "query" "text", "variables" "jsonb", "extensions" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."delete_user"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."delete_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_user"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."mss_catalog_meta"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mss_catalog_meta"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."mss_check_rate_limit"("p_bucket" "text", "p_identifier" "text", "p_max_requests" integer, "p_window_seconds" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mss_check_rate_limit"("p_bucket" "text", "p_identifier" "text", "p_max_requests" integer, "p_window_seconds" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."mss_current_release"() TO "anon";
GRANT ALL ON FUNCTION "public"."mss_current_release"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."mss_current_release"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."mss_entity_record"("p_entity_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mss_entity_record"("p_entity_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mss_finance_by_scheme"("p_scheme_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mss_finance_by_scheme"("p_scheme_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mss_lookup_catalog"("p_catalog" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mss_lookup_catalog"("p_catalog" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mss_rate_limit_status"("p_bucket" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mss_rate_limit_status"("p_bucket" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mss_relationships"("p_entity_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mss_relationships"("p_entity_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mss_scheme_detail"("p_scheme_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mss_scheme_detail"("p_scheme_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mss_search_data"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mss_search_data"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."rls_auto_enable"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."safe_cast_to_numeric"("val" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."safe_cast_to_numeric"("val" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."safe_cast_to_numeric"("val" "text") TO "service_role";



GRANT ALL ON TABLE "public"."ai_conversations" TO "anon";
GRANT ALL ON TABLE "public"."ai_conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."ai_conversations" TO "service_role";



GRANT ALL ON TABLE "public"."ai_messages" TO "anon";
GRANT ALL ON TABLE "public"."ai_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."ai_messages" TO "service_role";



GRANT ALL ON TABLE "public"."api_rate_limits" TO "service_role";



GRANT ALL ON TABLE "public"."audit_log" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_log" TO "service_role";



GRANT ALL ON SEQUENCE "public"."audit_log_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."audit_log_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."audit_log_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."beneficiary_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."beneficiary_categories" TO "service_role";



GRANT ALL ON TABLE "public"."bug_reports" TO "anon";
GRANT ALL ON TABLE "public"."bug_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."bug_reports" TO "service_role";



GRANT INSERT,MAINTAIN ON TABLE "public"."chat_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."chat_logs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."chat_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."chat_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."chat_logs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."departments" TO "authenticated";
GRANT ALL ON TABLE "public"."departments" TO "service_role";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."feature_requests" TO "anon";
GRANT ALL ON TABLE "public"."feature_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."feature_requests" TO "service_role";



GRANT ALL ON TABLE "public"."feedback" TO "anon";
GRANT ALL ON TABLE "public"."feedback" TO "authenticated";
GRANT ALL ON TABLE "public"."feedback" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."organization_memberships" TO "authenticated";
GRANT ALL ON TABLE "public"."organization_memberships" TO "service_role";



GRANT ALL ON TABLE "public"."organizations" TO "authenticated";
GRANT ALL ON TABLE "public"."organizations" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."promo_alerts" TO "anon";
GRANT ALL ON TABLE "public"."promo_alerts" TO "authenticated";
GRANT ALL ON TABLE "public"."promo_alerts" TO "service_role";



GRANT ALL ON TABLE "public"."question_options" TO "anon";
GRANT ALL ON TABLE "public"."question_options" TO "authenticated";
GRANT ALL ON TABLE "public"."question_options" TO "service_role";



GRANT ALL ON TABLE "public"."questionnaire_sessions" TO "anon";
GRANT ALL ON TABLE "public"."questionnaire_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."questionnaire_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."questions" TO "anon";
GRANT ALL ON TABLE "public"."questions" TO "authenticated";
GRANT ALL ON TABLE "public"."questions" TO "service_role";



GRANT ALL ON TABLE "public"."recent_schemes" TO "anon";
GRANT ALL ON TABLE "public"."recent_schemes" TO "authenticated";
GRANT ALL ON TABLE "public"."recent_schemes" TO "service_role";



GRANT ALL ON TABLE "public"."recommendations" TO "anon";
GRANT ALL ON TABLE "public"."recommendations" TO "authenticated";
GRANT ALL ON TABLE "public"."recommendations" TO "service_role";



GRANT ALL ON TABLE "public"."regions" TO "authenticated";
GRANT ALL ON TABLE "public"."regions" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."saved_schemes" TO "anon";
GRANT ALL ON TABLE "public"."saved_schemes" TO "authenticated";
GRANT ALL ON TABLE "public"."saved_schemes" TO "service_role";



GRANT ALL ON TABLE "public"."search_logs" TO "anon";
GRANT ALL ON TABLE "public"."search_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."search_logs" TO "service_role";



GRANT ALL ON TABLE "public"."startup_profiles" TO "anon";
GRANT ALL ON TABLE "public"."startup_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."startup_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."sync_history" TO "anon";
GRANT ALL ON TABLE "public"."sync_history" TO "authenticated";
GRANT ALL ON TABLE "public"."sync_history" TO "service_role";



GRANT ALL ON TABLE "public"."user_memory" TO "anon";
GRANT ALL ON TABLE "public"."user_memory" TO "authenticated";
GRANT ALL ON TABLE "public"."user_memory" TO "service_role";



GRANT ALL ON TABLE "public"."user_regions" TO "authenticated";
GRANT ALL ON TABLE "public"."user_regions" TO "service_role";



GRANT ALL ON TABLE "public"."user_responses" TO "anon";
GRANT ALL ON TABLE "public"."user_responses" TO "authenticated";
GRANT ALL ON TABLE "public"."user_responses" TO "service_role";



GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";












ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







