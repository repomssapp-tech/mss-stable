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

**Full rollout — all of `lib/`.** First the Discover + Profile flows (7 files),
then every remaining `.dart` file under `lib/` with spacing literals (32 more
files), via one mechanical transform (`scratchpad/migrate_spacing.py` then
`scratchpad/migrate_spacing_all.py`), not screen-by-screen hand edits.
~1050 `EdgeInsets` / `SizedBox` / `Wrap` / grid-spacing sites now go through
`AppSpacing.*`.

Value snaps applied uniformly (off-scale -> nearest step). The ones that move
real pixels: `10 -> 8` (~103 sites total), `14 -> 16` (~72), `5 -> 6` (~18),
`9 -> 8`, `11/13 -> 12`, `18 -> 20`. All <= 2 px; the full `flutter test`
suite (widget + layout tests) stays green.

Left as raw literals (not spacing steps — fixed control / image / avatar
dimensions): `1, 40, 43, 44, 48, 60, 80, 84, 85, 110, 120`. These are
allowed by the enforcement test (it only flags *on-scale* values). One
explicit `// spacing-ok`: `SizedBox(width: 40)` in
`about_you_profile_screen.dart` (centering counterweight).

## 4. Enforcement

`frontend/test/spacing_scale_test.dart` (runs in the normal `flutter test`
suite / CI), repo-wide over `lib/`:

1. Fails if any `EdgeInsets.all/symmetric/only/fromLTRB(...)` or
   `SizedBox(width:/height: ...)` — single- or multi-line — uses a bare
   numeric literal whose value is **on the scale** (`0, 2, 4, 6, 8, 12, 16,
   20, 24, 32`). Off-scale measurements (48, 60, ...) are left alone.
   Escape hatch: `// spacing-ok` on the value's line.
2. Fails if `AppSpacing`'s declared steps ever drift from
   `{0, 2, 4, 6, 8, 12, 16, 20, 24, 32}`.

No new dependency (a `custom_lint` rule was considered and rejected as
disproportionate).

## 5. Rollout status

**Done — whole app.** All ~39 files migrated; enforcement is repo-wide.

Remaining judgement calls a reviewer should eyeball (no screenshots were
taken):

- The `10 -> 8` and `14 -> 16` snaps on dense screens
  (`msme_module_details_screen.dart`, `scheme_details_screen.dart`,
  `voice_assistant_overlay.dart`, `saarthi_home_screen.dart`).
- Multi-property `SizedBox(height: N, width: M, child: ...)` were migrated in
  place; confirm none changed a deliberate aspect ratio.

If any spot regresses, fix it with the right `AppSpacing` step or an explicit
`// spacing-ok`, not by reverting the file.
