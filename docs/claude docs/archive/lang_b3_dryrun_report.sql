do $$
declare rep jsonb;
begin
  select jsonb_build_object(
    'content_by_lang_and_type', (select jsonb_agg(jsonb_build_object('lang', lang, 'entity_type', entity_type, 'n', n) order by lang, entity_type)
        from (select lang, entity_type, count(*) n from catalog.content group by 1, 2) x),
    'scheme_partition', (select jsonb_agg(jsonb_build_object('has_ta', has_ta, 'has_hi', has_hi, 'n', n) order by has_ta, has_hi)
        from (select exists (select 1 from catalog.content t where t.entity_type = 'scheme' and t.entity_id = e.entity_id and t.lang = 'ta') as has_ta,
                     exists (select 1 from catalog.content h where h.entity_type = 'scheme' and h.entity_id = e.entity_id and h.lang = 'hi') as has_hi,
                     count(*) n
              from catalog.content e where e.entity_type = 'scheme' and e.lang = 'en' group by 1, 2) p),
    'origin_verified', (select jsonb_agg(jsonb_build_object('lang', lang, 'origin', origin, 'verified', verified, 'n', n) order by lang, origin, verified)
        from (select lang, origin, verified, count(*) n from catalog.content where lang <> 'en' group by 1, 2, 3) o)
  ) into rep;
  raise exception 'DRYRUN_REPORT (rolled back on purpose): %', rep::text;
end $$;
