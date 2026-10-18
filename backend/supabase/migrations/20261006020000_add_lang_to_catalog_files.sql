-- Migration: Add nullable lang column to admin.catalog_files
-- Ref: MASTER_PLAN_hindi_localization.md Phase P3
alter table admin.catalog_files
  add column if not exists lang text references catalog.language (code);

comment on column admin.catalog_files.lang is
  'ISO language code if this file is a language pack (e.g. "hi", "ta"); null for language-neutral or core bundle files.';
