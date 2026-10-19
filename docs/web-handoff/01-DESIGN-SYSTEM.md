# Design System — extracted from the Flutter app

Source of truth: `frontend/lib/utils/app_spacing.dart`, `constants.dart`, `app_theme.dart`, `responsive.dart`, cross-checked against `docs/UI_UX_DESIGN_SYSTEM.md`. Where code and that doc disagreed, **code wins** — see the discrepancy table below, and fix the doc separately if you want it corrected upstream.

## Spacing scale

An 8pt-ish grid, enforced in the app by a dedicated test (`test/spacing_scale_test.dart`) that fails the build if a raw numeric literal is used for padding/margin instead of a token. Keep that discipline on the web: define these once in Tailwind's `spacing` scale and never hardcode a pixel value in a component.

| Token | Value |
|---|---|
| `none` | 0px |
| `hairline` | 2px |
| `xs` | 4px |
| `tight` | 6px |
| `sm` | 8px |
| `md` | 12px |
| `lg` | 16px (default card/screen padding) |
| `xl` | 20px |
| `xxl` | 24px |
| `xxxl` | 32px (section breaks) |

## Colors

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#2563EB` | Royal blue — buttons, active states, links |
| `secondary` | `#1565C0` | Secondary blue accents |
| `accent` | `#FF9933` | Saffron accent (tricolor branding touches) |
| `success` | `#2E7D32` | Confirmations, verified badges |
| `warning` | `#FB8C00` | Alerts, closing-soon banners |
| `error` | `#D32F2F` | Validation errors, destructive actions |
| `background` | `#F8FAFC` | Page background |
| `surface` | `#FFFFFF` | Cards, sheets, inputs |
| `border` | `#E5E7EB` | Card/divider borders |
| `text-primary` | `#111827` | Headings, primary body text |
| `text-secondary` | `#6B7280` | Secondary/muted text |

**Gradients:**
- `blue-gradient`: `#F8FAFC → #E0F2FE → #EFF6FF`, top-left to bottom-right (used as the default scaffold/page background).
- `glass-gradient`: `white/70 → white/60`, top-left to bottom-right (glassmorphism overlays).

## Typography

Fonts are loaded from Google Fonts, no custom font files needed:
- **English:** Poppins (headlines, large numbers, bold emphasis), Inter (body text, controls, labels).
- **Tamil:** Noto Sans Tamil (body), Arima (accents) — only relevant if the web port supports Tamil too.

| Style | English (size/weight) | Tamil equivalent |
|---|---|---|
| Display Large | 28px / Bold | 26px / 1.35 line-height |
| Headline Medium | 22px / Bold | 20px / 1.35 line-height |
| Title Medium | 16px / SemiBold | 15px / 1.30 line-height |
| Body Regular | 14px / Regular | 13px / 1.45 line-height |
| Body Small | 12px / Medium | 11.5px / 1.40 line-height |
| Label Small | 10.5px / Bold | 10px / 1.25 line-height |

## Shape & elevation

- Card radius: 12–16px.
- Chip/pill radius: 20–30px (fully rounded).
- Primary button radius: 12px, minimum height 52px, no shadow/elevation (flat design).
- Bottom-nav-equivalent (site header/nav on web): subtle top border in `border` color, no heavy shadow.
- Inputs: filled background (`surface` or a light tint), 12px radius outline; default border `border` color, focused border `primary` at ~1.8px.

## Icons

100% Material Icons throughout the app (476+ usages, no custom icon font, no other icon set). For the web, use `@mui/icons-material` or `lucide-react` mapped to the same semantic icons — there's no proprietary icon asset to extract.

## Responsive behavior

The Flutter app has **no breakpoint system** — it's mobile-only and uses a linear scale-by-screen-width helper (`adaptiveSize()`, reference width 375px, clamped) rather than Tailwind-style breakpoints. This means **there is no existing responsive design to port** for tablet/desktop layouts — the web team designs those fresh. Use Tailwind's standard breakpoints (`sm/md/lg/xl/2xl`) and treat the extracted spacing/type scale above as the mobile (`base`) values.

## Component inventory (Flutter widget → React component mapping)

Actual widget folders are `frontend/lib/widgets/{assistant,common,legal,scheme}/` (not buttons/cards/dialogs/inputs — that folder structure doesn't exist in this codebase).

| Flutter widget | Purpose | Suggested React equivalent |
|---|---|---|
| `common/custom_button.dart` | Primary/secondary button | `<Button variant="primary\|secondary">` |
| `common/custom_confirm_dialog.dart` | Confirmation modal | `<ConfirmDialog>` |
| `common/app_toast.dart` | Toast/snackbar | `<Toast>` (e.g. via `sonner` or `react-hot-toast`) |
| `common/gradient_scaffold.dart` | Page shell with gradient background | A `<PageShell>` layout wrapper applying `blue-gradient` |
| `common/standard_page_header.dart` | Consistent page title + back button | `<PageHeader title back? />` |
| `common/floating_logo.dart` | Small floating brand mark | `<FloatingLogo>` |
| `common/anti_gravity_hero_section.dart` | Hero banner section | `<HeroSection>` |
| `scheme/scheme_card.dart` | Scheme list-item card | `<SchemeCard>` |
| `scheme/category_card.dart` | Category tile | `<CategoryCard>` |
| `scheme/filter_panel.dart` | Filter bottom sheet/modal | `<FilterPanel>` (modal or drawer on web) |
| `scheme/catalog_freshness_footer.dart` | "Catalog updated X" footer | `<CatalogFreshnessFooter>` |
| `legal/legal_consent_section.dart` | ToS/Privacy checkbox row | `<ConsentCheckbox>` |
| `legal/legal_document_modal.dart` | Full legal text modal | `<LegalDocumentModal>` |
| `assistant/voice_assistant_overlay.dart` + `voice/*` | Voice/AI companion overlay UI | Out of scope for initial web port (see README) |
| `assistant/smart_assessment_bottom_sheet.dart` + `smart_assessment/*` | Guided eligibility question flow | `<SmartAssessmentFlow>` |
| `assistant/voice_edge_painter.dart` | Custom waveform canvas painter | Would need a `<canvas>`/SVG equivalent if voice UI is ported later |

## Asset inventory (`frontend/assets/`)

- `images/Logo/` — `Logo.webp`, `Logo icon.webp` (copied into `docs/web-handoff/assets/logo/`), plus partner logos (RIT, SSS TN Chapter) not needed for the web product itself.
- `images/Background/` — 12 WebP banners (home/login backgrounds, alert/promo banners, splash, onboarding). Not copied here (large, screen-specific) — pull individually from `frontend/assets/images/Background/` as each page is built.
- `images/States assets/` — 28 state emblem WebPs + 28 state outline-map WebPs (note: some filenames have typos/casing inconsistencies in the source, e.g. `Anrunachal pradhesh.webp` — clean up names when porting rather than propagating them).
- `images/saarthi/`, `images/supporting assets/` — companion-mode/voice avatar art, out of scope per README.

## Tailwind config seed

A starting `tailwind.config.js` extending Tailwind's defaults with the tokens above is at [`tailwind.config.seed.js`](tailwind.config.seed.js) in this directory — copy it into the new Next.js project and rename to `tailwind.config.js`.
