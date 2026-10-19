insert into public.organizations (id, code, name)
values ('10000000-0000-0000-0000-000000000001', 'TNGOV', 'Tamil Nadu Government')
on conflict (id) do update set name = excluded.name;

-- public.regions was archived (renamed to public._deprecated_regions) by
-- 20260905080538_archive_zero_row_scaffold_tables.sql -- zero-row scaffold,
-- never shipped. Seeding it is no longer meaningful; removed rather than
-- reversed.

insert into public.departments (id, organization_id, code, name)
values
  (
    '30000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'SOCIAL_WELFARE',
    'Social Welfare and Women Empowerment Department'
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    'AGRICULTURE',
    'Agriculture and Farmers Welfare Department'
  )
on conflict (id) do update set name = excluded.name, active = true;

-- public.beneficiary_categories was archived (renamed to
-- public._deprecated_beneficiary_categories) by the same migration -- same
-- reasoning as public.regions above.
