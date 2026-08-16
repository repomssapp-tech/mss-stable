-- ===========================================================
-- Migration: catalog_parity_closure
-- Project : IN Schemes
-- Purpose : The offline Flutter bundle ships 15 catalog files (1216
--           entities). Supabase's catalog schema only ever imported 10 of
--           them (971 entities) -- applicability_matrix,
--           enterprise_classification, msme_privilege,
--           business_enablement, and cluster_assistance were never given
--           tables at all. This closes that gap: 5 new tables, same
--           hybrid pattern as the existing catalog.* tables. Purely
--           additive -- no existing table or row is touched.
-- ===========================================================

begin;

create table if not exists catalog.applicability_matrix (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,

  -- hybrid relational columns
  scheme_id text references catalog.scheme(id) on delete cascade deferrable initially deferred,
  government_level text,
  department_authority_id text references catalog.authority(id) on delete set null,
  sector_text text,
  district_text text
);

create table if not exists catalog.enterprise_classification (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,

  -- hybrid relational columns
  code text,
  dimension text,
  investment_max_inr numeric(15,2),
  turnover_max_inr numeric(15,2)
);

create table if not exists catalog.msme_privilege (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,

  -- hybrid relational columns
  privilege_type text,
  statute text
);

create table if not exists catalog.business_enablement (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,

  -- hybrid relational columns
  enablement_type text,
  provider_authority_id text references catalog.authority(id) on delete set null,
  online_url text
);

create table if not exists catalog.cluster_assistance (
  id text primary key,
  version text not null,
  status text not null default 'DRAFT' check (status in ('DRAFT', 'READY_FOR_REVIEW', 'REVIEWED', 'APPROVED', 'PUBLISHED', 'ARCHIVED')),
  checksum text not null,
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  record_json jsonb not null,

  -- hybrid relational columns
  cluster_name text,
  sector text,
  administering_authority_id text references catalog.authority(id) on delete set null
);

create index if not exists catalog_applicability_matrix_scheme_idx on catalog.applicability_matrix (scheme_id);

-- RLS: mirror the existing catalog.* tables exactly (public read of
-- PUBLISHED rows, admin/content-editor manage all).
alter table catalog.applicability_matrix enable row level security;
alter table catalog.enterprise_classification enable row level security;
alter table catalog.msme_privilege enable row level security;
alter table catalog.business_enablement enable row level security;
alter table catalog.cluster_assistance enable row level security;

create policy "Public read published applicability_matrix" on catalog.applicability_matrix
  for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Admins manage applicability_matrix" on catalog.applicability_matrix
  for all to authenticated
  using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']))
  with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));

create policy "Public read published enterprise_classification" on catalog.enterprise_classification
  for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Admins manage enterprise_classification" on catalog.enterprise_classification
  for all to authenticated
  using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']))
  with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));

create policy "Public read published msme_privilege" on catalog.msme_privilege
  for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Admins manage msme_privilege" on catalog.msme_privilege
  for all to authenticated
  using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']))
  with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));

create policy "Public read published business_enablement" on catalog.business_enablement
  for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Admins manage business_enablement" on catalog.business_enablement
  for all to authenticated
  using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']))
  with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));

create policy "Public read published cluster_assistance" on catalog.cluster_assistance
  for select to anon, authenticated using (status = 'PUBLISHED');
create policy "Admins manage cluster_assistance" on catalog.cluster_assistance
  for all to authenticated
  using (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']))
  with check (private.has_admin_role(auth.uid(), array['administrator', 'content_editor']));

commit;
