do $$
declare rep jsonb;
begin
  select jsonb_build_object(
    'content_en', (select jsonb_object_agg(entity_type, n) from (select entity_type, count(*) n from catalog.content_en group by 1) x),
    'content_ta', (select jsonb_object_agg(entity_type, n) from (select entity_type, count(*) n from catalog.content_ta group by 1) x),
    'content_hi', (select jsonb_object_agg(entity_type, n) from (select entity_type, count(*) n from catalog.content_hi group by 1) x),
    'scheme_partition', (select jsonb_agg(jsonb_build_object('has_ta', has_ta, 'has_hi', has_hi, 'n', n) order by has_ta, has_hi)
        from (select (t.entity_id is not null) has_ta, (h.entity_id is not null) has_hi, count(*) n
              from catalog.content_en e
              left join catalog.content_ta t using (entity_type, entity_id)
              left join catalog.content_hi h using (entity_type, entity_id)
              where e.entity_type = 'scheme' group by 1, 2) p),
    'origin_verified', (select jsonb_agg(jsonb_build_object('lang', lang, 'origin', origin, 'verified', verified, 'n', n) order by lang, origin, verified)
        from (select 'ta' lang, origin, verified, count(*) n from catalog.content_ta group by 2, 3
              union all select 'hi', origin, verified, count(*) from catalog.content_hi group by 2, 3) o)
  ) into rep;
  raise exception 'DRYRUN_REPORT (rolled back on purpose): %', rep::text;
end $$;
