-- UNTESTED by reviewer (these tables do not exist in the reviewer's sandbox). If one errors, paste the error text.
-- G1. top-level keys of record_json for authority / institution / common
select 'authority' as t, k, count(*) from catalog.authority, jsonb_object_keys(record_json) k group by 2
union all select 'institution', k, count(*) from catalog.institution, jsonb_object_keys(record_json) k group by 2
union all select 'common', k, count(*) from catalog.common, jsonb_object_keys(record_json) k group by 2
order by 1, 3 desc;
-- G2. two sample common records, truncated
select id, left(record_json::text, 1200) as record_head from catalog.common order by id limit 2;
-- I1. type/default of public.profiles.language
select column_name, data_type, udt_name, column_default from information_schema.columns
where table_schema = 'public' and table_name = 'profiles' and column_name = 'language';
-- I2. CHECK constraints on public.profiles (look for a language whitelist)
select conname, pg_get_constraintdef(oid) as definition from pg_constraint
where conrelid = 'public.profiles'::regclass and contype = 'c';
-- J1. columns of admin.catalog_files
select column_name, data_type from information_schema.columns
where table_schema = 'admin' and table_name = 'catalog_files' order by ordinal_position;
-- J2. 15 sample rows of admin.catalog_files
select * from admin.catalog_files limit 15;
-- J3. latest 3 releases
select version, release_version, status, is_current, record_counts, published_at
from admin.catalog_releases order by published_at desc nulls last limit 3;
