-- ===========================================================
-- Migration: recreate_promo_alerts
-- Project  : MSS - MSME Schemes Search
-- Purpose : database_architecture_v2 (20260805000000) dropped public.promo_alerts
--           as part of its legacy-table cleanup sweep, but never recreated it --
--           it isn't part of the catalog/admin schema. This table is still
--           read by the Flutter Home screen promo banner (AppProvider), so
--           restore it.
-- ===========================================================

CREATE TABLE IF NOT EXISTS public.promo_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    badge_text TEXT NOT NULL,
    badge_text_color TEXT DEFAULT '#EA580C',
    badge_bg_color TEXT DEFAULT '#FFF7ED',
    bg_gradient_start TEXT DEFAULT '#FFF7ED',
    bg_gradient_end TEXT DEFAULT '#FFFFEDD5',
    btn_text TEXT DEFAULT 'View Details',
    btn_color TEXT DEFAULT '#EA580C',
    target_route TEXT DEFAULT 'notifications',
    graphic_type TEXT DEFAULT 'calendar',
    target_gender TEXT,
    target_state TEXT,
    target_community TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.promo_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access to promo_alerts" ON public.promo_alerts;
CREATE POLICY "Allow public read access to promo_alerts"
ON public.promo_alerts
FOR SELECT
USING (true);

INSERT INTO public.promo_alerts (
    title, badge_text, badge_text_color, badge_bg_color, bg_gradient_start, bg_gradient_end, btn_text, btn_color, target_route, graphic_type
)
SELECT * FROM (VALUES
    (
        'PMEGP (Closing in 5 Days)',
        'Alert',
        '#EA580C',
        '#FFF7ED',
        '#FFF7ED',
        '#FFFFEDD5',
        'View Details',
        '#EA580C',
        'notifications',
        'calendar'
    ),
    (
        'TN Export Promotion Scheme',
        'New Scheme',
        '#16A34A',
        '#DCFCE7',
        '#F0FDF4',
        '#DCFCE7',
        'Explore',
        '#16A34A',
        'discover_results',
        'ship'
    )
) AS seed(title, badge_text, badge_text_color, badge_bg_color, bg_gradient_start, bg_gradient_end, btn_text, btn_color, target_route, graphic_type)
WHERE NOT EXISTS (SELECT 1 FROM public.promo_alerts);
