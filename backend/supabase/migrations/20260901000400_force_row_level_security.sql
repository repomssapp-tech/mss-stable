-- ===========================================================
-- Migration: force_row_level_security
-- Project : IN Schemes (MSS App)
-- Purpose : M7 -- every RLS-enabled table in this project has
--           relforcerowsecurity = false, so the table OWNER (and any future
--           SECURITY DEFINER function owned by it) bypasses RLS silently.
--           FORCE it on the PII and app-side RBAC tables so a definer /
--           trigger mistake fails closed instead of leaking.
--
--           Verified safe for public.profiles: this project has NO trigger
--           on auth.users and NO handle_new_user() function (repo grep is
--           clean). Profile rows are created by the client via an
--           authenticated PostgREST upsert, where auth.uid() is set and the
--           "Profiles insert access" WITH CHECK (auth.uid() = id) policy
--           passes -- FORCE does not break signup. FK cascade deletes from
--           auth.users (delete_user) run as the system and are not subject
--           to RLS.
--
--           Deliberately EXCLUDED:
--             - public.audit_log: append-only, only a SELECT policy and no
--               INSERT grant to authenticated; its writer (if any) is a
--               definer / service_role path FORCE could break. Revisit when
--               that path is known.
--             - admin.*: managed from the Supabase dashboard as `postgres`,
--               where auth.uid() is NULL; FORCE would lock those tables
--               against their only maintenance path.
--             - catalog.*: owner-context bulk import / publish jobs rely on
--               running as the table owner.
-- ===========================================================

begin;

alter table public.profiles                 force row level security;
alter table public.startup_profiles         force row level security;

alter table public.organizations            force row level security;
alter table public.organization_memberships force row level security;
alter table public.roles                    force row level security;
alter table public.user_roles               force row level security;
alter table public.regions                  force row level security;
alter table public.user_regions             force row level security;
alter table public.departments              force row level security;
alter table public.beneficiary_categories   force row level security;

commit;

-- ===========================================================
-- Rollback (manual):
--   alter table public.profiles no force row level security;
--   ... (repeat for each table above)
-- ===========================================================
