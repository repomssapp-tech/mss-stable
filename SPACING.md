# Spacing scale (Phase 6)

## 1. Inventory

Every hardcoded `EdgeInsets` / `SizedBox` / `Wrap`/grid spacing literal in
`frontend/lib/` (Sept 2026): **1157 sites across 40 files.**

Frequency of the distinct values (merged across `EdgeInsets.all`,
`EdgeInsets.symmetric`, `SizedBox(height:)`, `SizedBox(width:)`):

| value | ~count | | value | ~count |
|------:|-------:|-|------:|-------:|
| 8  | ~230 | | 20 | ~55 |
| 12 | ~160 | | 10 | ~60 |
| 16 | ~150 | | 24 | ~45 |
| 4  | ~120 | | 14 | ~35 |
| 6  | ~110 | | 2  | ~45 |
| | | | 32 / 5 / 7 / 9 / 11 / 13 / 18 / 28 / 36 | one-offs |

**Dominant values: 4, 6, 8, 12, 16, 20, 24.** Plus `2` (hairline) and `32`
(section break). Everything else (5, 7, 9, 10, 11, 13, 14, 18, 28, 36, and
fractional `2.5`) is noise — the same visual intent expressed a few pixels
differently on different screens.

Only pre-existing spacing constants: `AppCardStyle.chipSpacing = 6.0` /
`chipRunSpacing = 6.0` (`lib/utils/app_card_style.dart`).

## 2. The scale

`frontend/lib/utils/app_spacing.dart` — `AppSpacing`:

| name | value | use |
|------|------:|-----|
| `none`     | 0  | |
| `hairline` | 2  | hairline separators, icon nudges |
| `xs`       | 4  | |
| `tight`    | 6  | tight chip / label->field gaps |
| `sm`       | 8  | |
| `md`       | 12 | |
| `lg`       | 16 | default card / screen padding |
| `xl`       | 20 | |
| `xxl`      | 24 | |
| `xxxl`     | 32 | section breaks |

Off-scale values snap to the nearest step. The two snaps that move real
pixels in the migrated flows:

- **10 -> 8** (`sm`) — 29 sites
- **14 -> 16** (`lg`) — 26 sites

Both are within ~2 px and were reviewed against the widget tests (no overflow,
224 -> 226 passing). Everything else was a pure rename of an already-on-scale
value.

## 3. What was migrated

Discover + Profile flows only (7 files, ~365 `AppSpacing.*` references), via a
single mechanical transform (`scratchpad/migrate_spacing.py`), not
screen-by-screen hand edits:

- `screens/regular_mode/categories_screen.dart` (Discover, 183 sites)
- `screens/regular_mode/search_results_screen.dart`
- `screens/regular_mode/basic_profile_screen.dart`
- `screens/regular_mode/location_profile_screen.dart`
- `screens/regular_mode/about_you_profile_screen.dart`
- `screens/regular_mode/eligibility_profile_screen.dart`
- `screens/regular_mode/eligibility_results_screen.dart`

One value kept as a literal: `SizedBox(width: 40)` in
`about_you_profile_screen.dart` — a centering counterweight for the leading
`IconButton`, not a gap. Marked `// spacing-ok`.

## 4. Enforcement

`frontend/test/spacing_scale_test.dart` (runs in the normal `flutter test`
suite / CI):

1. Fails if any file in `_enforcedFiles` (the 7 above) contains a bare
   numeric literal inside `EdgeInsets.all/symmetric/only/fromLTRB(...)` or
   `SizedBox(width:/height: N)`. Escape hatch: `// spacing-ok` on the line.
2. Fails if `AppSpacing`'s declared steps ever drift from
   `{0, 2, 4, 6, 8, 12, 16, 20, 24, 32}`.

No new dependency (a `custom_lint` rule was considered and rejected as
disproportionate). To widen the rule, add paths to `_enforcedFiles`.

## 5. Full-rollout cost (rest of the app)

**~790 remaining sites across 33 files.** Largest:

| file | sites |
|------|------:|
| `screens/regular_mode/msme_module_details_screen.dart` | 89 |
| `screens/regular_mode/home_screen.dart` | 71 |
| `widgets/voice_assistant_overlay.dart` | 64 |
| `screens/regular_mode/scheme_details_screen.dart` | 59 |
| `screens/companion_mode/saarthi_home_screen.dart` | 58 |
| `screens/notifications_screen.dart` | 56 |
| `screens/regular_mode/help_support_screen.dart` | 54 |
| `screens/regular_mode/search_screen.dart` | 40 |
| ... 25 more files | <= 39 each |

The transform generalises — extend `TARGETS` in the migration script and
`_enforcedFiles` in the test. On this batch it needed exactly **one** manual
annotation across 335 sites, so the code change is ~95% mechanical.

The real cost is QA, not code: `flutter analyze` + a visual pass on each of
the ~33 screens to confirm the 10->8 / 14->16 snaps (and any new outliers per
file) don't shift a layout. **Estimate: 1-2 engineer-days**, dominated by
screenshot diffing and review, spread over as many PRs as makes review
manageable (suggest grouping by flow: companion mode, scheme detail, home,
settings/legal, notifications).
