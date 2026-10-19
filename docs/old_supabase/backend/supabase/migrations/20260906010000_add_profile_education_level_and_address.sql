-- ===========================================================
-- Migration: add_profile_education_level_and_address
-- Project : MSS App
-- Purpose : Onboarding collects `educationLevel` and `address`, both read
--           by RecommendationEngine, but public.profiles had no column for
--           either -- UserProfile.toSupabase() silently dropped them and
--           every getProfile() reset them to blank. `qualification` was
--           doubling as education storage; give both fields a real home.
--           (Applied to project houpzsxmwemoztpuigmo on 2026-09-06.)
-- ===========================================================

alter table public.profiles
  add column if not exists education_level text,
  add column if not exists address text;

comment on column public.profiles.education_level is
  'Highest education level (School/Diploma/Undergraduate/Postgraduate/PhD). '
  'Used in RecommendationEngine education scoring. Onboarding also writes the '
  'same value to `qualification`.';
comment on column public.profiles.address is
  'Free-text combined address from onboarding (granular parts also stored in '
  'house/street/area/village/city).';

-- Backfill from qualification where education was already captured.
update public.profiles
  set education_level = qualification
  where (education_level is null or education_level = '')
    and qualification is not null and qualification <> '';
