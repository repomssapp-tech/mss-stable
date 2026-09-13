-- ===========================================================
-- Migration: add_profile_religion_and_first_gen
-- Project  : MSS - MSME Schemes Search
-- Purpose : `religion` and `firstGenGraduate` are collected during
--           onboarding, cached locally, and actively used in
--           RecommendationEngine scoring (recommendation_engine.dart:118,
--           444), but were never sent to Supabase at all -- absent from
--           UserProfile.toSupabase() and with no column anywhere to
--           receive them. Since getProfile() fully replaces the in-memory
--           profile (`_profile = dbProfile`) on every auth-state change,
--           login, and background sync, both fields silently reset to
--           blank/false on any of those triggers.
--
--           `public.startup_profiles` (where firstGenGraduate's own doc
--           comment suggested it belonged, as
--           is_first_generation_entrepreneur) is not a fix: the app never
--           reads that table back into UserProfile at all (confirmed via
--           grep -- only a `.select('id')` existence check for upsert
--           conflict resolution, never the row's content). `public.profiles`
--           is the only table the app actually round-trips through
--           (getProfile() -> UserProfile.fromJson()), so both fields go
--           there instead.
-- ===========================================================

alter table public.profiles
  add column if not exists religion text,
  add column if not exists first_gen_graduate boolean not null default false;

comment on column public.profiles.religion is
  'Self-reported religion, used for minority-category scheme matching (RecommendationEngine). Free text from the onboarding wizard, not a constrained enum.';
comment on column public.profiles.first_gen_graduate is
  'Whether the user is a first-generation graduate, used for NEEDS-scheme recommendation scoring.';
