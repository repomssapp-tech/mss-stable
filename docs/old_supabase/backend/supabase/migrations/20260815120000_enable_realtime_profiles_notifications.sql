-- ===========================================================
-- Migration: enable_realtime_profiles_notifications
-- Project  : MSS - MSME Schemes Search
-- Purpose : AppProvider subscribes to realtime changes on
--           public.profiles and public.notifications
--           (see frontend/lib/providers/app_state_provider.dart), but
--           neither table was ever added to the supabase_realtime
--           publication, so every subscribe attempt fails with
--           RealtimeSubscribeException(status: channelError).
-- ===========================================================

alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.notifications;
