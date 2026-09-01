-- SECURITY DEFINER functions receive EXECUTE from PUBLIC by default.
-- The search corpus is an internal dependency of the Edge Function only.
revoke all on function public.mss_search_data() from public, anon, authenticated;
grant execute on function public.mss_search_data() to service_role;
