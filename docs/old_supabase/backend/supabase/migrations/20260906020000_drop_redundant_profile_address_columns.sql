-- ===========================================================
-- Migration: drop_redundant_profile_address_columns
-- Project : MSS App
-- Purpose : The onboarding address step has a single "Door/Street" input
--           that was written into BOTH `house` and `street` (always
--           identical), and "City/District" that fills `city` and
--           `district` identically when there is no comma. `village` and
--           the `address` column added in the previous migration were
--           never populated. Keep the granular set that the form actually
--           produces: house / area / city / district / state / pincode.
--           (Applied to project houpzsxmwemoztpuigmo on 2026-09-06.)
-- ===========================================================

alter table public.profiles
  drop column if exists street,
  drop column if exists village,
  drop column if exists address;
