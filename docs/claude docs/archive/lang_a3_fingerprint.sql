-- FINGERPRINT of existing data. Run in Part A (before) and Part C (after). The two outputs must be IDENTICAL.
select 'scheme' t, count(*), md5(string_agg(md5(coalesce(record_json::text,'')||coalesce(name_en,'')||coalesce(name_ta,'')), '' order by id)) from catalog.scheme
union all select 'authority', count(*), md5(string_agg(md5(coalesce(record_json::text,'')||name_en||coalesce(name_ta,'')), '' order by id)) from catalog.authority
union all select 'institution', count(*), md5(string_agg(md5(coalesce(record_json::text,'')||name_en||coalesce(name_ta,'')), '' order by id)) from catalog.institution;
