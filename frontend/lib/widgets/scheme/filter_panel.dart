import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_state_provider.dart';
import '../../services/catalog/centralized_translator.dart';
import '../../models/scheme_model.dart';
import '../../models/scheme_filter.dart';
import '../../utils/constants.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_spacing.dart';

/// Lean scheme filter sheet -- three catalog-real facet groups, static
/// counts, a fixed grid so chips never reflow. Replaces the old 18-field
/// panel and the dead FilterBottomSheet.
class FilterPanel extends StatefulWidget {
  final VoidCallback? onApplied;

  /// The scheme list this panel's counts and "Show N schemes" button should
  /// be scoped to -- e.g. the caller's current text-search results. Falls
  /// back to the full catalog (`AppProvider.allSchemes`) when the caller has
  /// no active scope (browsing categories/ministries/states directly).
  final List<Scheme>? baseSchemes;

  const FilterPanel({super.key, this.onApplied, this.baseSchemes});

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late String _coverage; // '' | 'nationwide' | 'state'
  late String _state;
  late Set<String> _types;
  late Set<String> _beneficiaries;

  int _countsForLen = -1;
  Map<String, int> _counts = const {};

  @override
  void initState() {
    super.initState();
    final f = Provider.of<AppProvider>(context, listen: false).filters;
    _state = (f['state'] ?? '').toString();
    final cov = (f['coverage'] ?? '').toString();
    _coverage = cov.isNotEmpty
        ? cov
        : (_state.isNotEmpty && _state.toLowerCase() != 'all' ? 'state' : '');
    _types = {..._asList(f['schemeTypes'])};
    _beneficiaries = {..._asList(f['beneficiaries'])};
  }

  List<String> _asList(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : const [];

  Map<String, dynamic> get _draft => {
    'coverage': _coverage == 'nationwide' ? 'nationwide' : '',
    'state': _coverage == 'state' ? _state : '',
    'schemeTypes': _types.toList(),
    'beneficiaries': _beneficiaries.toList(),
  };

  /// Per-option totals over the whole catalog. Static -- they do not react
  /// to what is currently selected, so chip widths never change and the
  /// grid never reflows. Coverage is a mutually-exclusive partition
  /// (nationwide vs state-specific) so the numbers add up.
  Map<String, int> _computeCounts(List<Scheme> catalog, String profileState) {
    final m = <String, int>{};
    m['cov:nationwide'] = catalog.where(schemeIsNationwide).length;
    if (profileState.isNotEmpty) {
      final st = profileState.toLowerCase();
      m['cov:state'] = catalog
          .where(
            (s) => !schemeIsNationwide(s) && s.state.toLowerCase().contains(st),
          )
          .length;
    }
    for (final g in kSchemeTypeGroups) {
      m['type:${g.id}'] = catalog.where(g.matches).length;
    }
    for (final (code, _) in kBeneficiaryOptions) {
      m['ben:$code'] = catalog
          .where(
            (s) =>
                s.specialCategories.map((e) => e.toLowerCase()).contains(code),
          )
          .length;
    }
    return m;
  }

  void _apply() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final d = _draft;
    provider.updateFilter('coverage', d['coverage']);
    provider.updateFilter('state', d['state']);
    provider.updateFilter('schemeTypes', d['schemeTypes']);
    provider.updateFilter('beneficiaries', d['beneficiaries']);
    Navigator.pop(context);
    widget.onApplied?.call();
  }

  void _clear() => setState(() {
    _coverage = '';
    _state = '';
    _types = {};
    _beneficiaries = {};
  });

  void _prefillFromProfile() {
    final profile = Provider.of<AppProvider>(context, listen: false).profile;
    final g = profile.gender.toLowerCase();
    final c = profile.community.trim().toLowerCase();
    setState(() {
      if (profile.state.trim().isNotEmpty) {
        _coverage = 'state';
        _state = profile.state.trim();
      }
      // Beneficiary chips inferred from the profile's own demographics.
      if (g.contains('female') || g.contains('woman')) {
        _beneficiaries.add('women');
      }
      if (g.contains('trans')) _beneficiaries.add('transgender');
      if (c == 'sc' || c.contains('scheduled caste')) {
        _beneficiaries.add('sc');
      }
      if (c == 'st' || c.contains('scheduled tribe')) {
        _beneficiaries.add('st');
      }
      if (c.contains('minorit')) _beneficiaries.add('minority');
      final d = profile.disability.trim().toLowerCase();
      if (d.isNotEmpty && d != 'none') _beneficiaries.add('differently_abled');
      if (profile.veteran) _beneficiaries.add('ex_servicemen');
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final catalog = widget.baseSchemes ?? provider.allSchemes;
    final profileState = provider.profile.state.trim();

    if (catalog.length != _countsForLen) {
      _counts = _computeCounts(catalog, profileState);
      _countsForLen = catalog.length;
    }

    final active = activeSchemeFilterCount(_draft);
    final showCount = applySchemeFilters(catalog, _draft).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        gradient: AppConstants.blueGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xs,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.filterTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (active > 0)
                  GestureDetector(
                    onTap: _clear,
                    child: Text(
                      context.l10n.filterClearAll,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profileState.isNotEmpty) ...[
                    GestureDetector(
                      onTap: _prefillFromProfile,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_pin_circle_outlined,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            context.l10n.filterUseMyProfile(
                              CentralizedTranslator.instance.localizeTag(
                                profileState,
                              ),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _group(context.l10n.filterGroupCoverage, 2, [
                    _ChipSpec(
                      context.l10n.filterCoverageNationwide,
                      _counts['cov:nationwide'] ?? 0,
                      _coverage == 'nationwide',
                      () => setState(
                        () => _coverage = _coverage == 'nationwide'
                            ? ''
                            : 'nationwide',
                      ),
                    ),
                    if (profileState.isNotEmpty)
                      _ChipSpec(
                        CentralizedTranslator.instance.localizeTag(
                          profileState,
                        ),
                        _counts['cov:state'] ?? 0,
                        _coverage == 'state' &&
                            _state.toLowerCase() == profileState.toLowerCase(),
                        () => setState(() {
                          final on =
                              _coverage == 'state' &&
                              _state.toLowerCase() ==
                                  profileState.toLowerCase();
                          _coverage = on ? '' : 'state';
                          _state = on ? '' : profileState;
                        }),
                      ),
                  ]),
                  _group(context.l10n.filterGroupOffers, 2, [
                    for (final g in kSchemeTypeGroups)
                      _ChipSpec(
                        _typeLabel(g.id),
                        _counts['type:${g.id}'] ?? 0,
                        _types.contains(g.id),
                        () => setState(
                          () => _types.contains(g.id)
                              ? _types.remove(g.id)
                              : _types.add(g.id),
                        ),
                      ),
                  ]),
                  _group(context.l10n.filterGroupFor, 3, [
                    for (final (code, _) in kBeneficiaryOptions)
                      if ((_counts['ben:$code'] ?? 0) >= 4)
                        _ChipSpec(
                          _benLabel(code),
                          _counts['ben:$code'] ?? 0,
                          _beneficiaries.contains(code),
                          () => setState(
                            () => _beneficiaries.contains(code)
                                ? _beneficiaries.remove(code)
                                : _beneficiaries.add(code),
                          ),
                        ),
                  ]),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.l10n.filterShowSchemes(showCount),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Localized display label for a [SchemeTypeGroup.id]. The model keeps a
  /// stable English label for logging/tests; the UI shows the translation.
  String _typeLabel(String id) {
    final l = context.l10n;
    switch (id) {
      case 'loans':
        return l.filterTypeLoans;
      case 'subsidies':
        return l.filterTypeSubsidies;
      case 'grants':
        return l.filterTypeGrants;
      case 'guarantee':
        return l.filterTypeGuarantee;
      case 'training':
        return l.filterTypeTraining;
      case 'market':
        return l.filterTypeMarket;
      case 'infra':
        return l.filterTypeInfra;
    }
    return id;
  }

  /// Localized display label for a beneficiary code.
  String _benLabel(String code) {
    final l = context.l10n;
    switch (code) {
      case 'women':
        return l.filterBenWomen;
      case 'sc':
        return l.filterBenSc;
      case 'st':
        return l.filterBenSt;
      case 'differently_abled':
        return l.filterBenDifferentlyAbled;
      case 'transgender':
        return l.filterBenTransgender;
      case 'minority':
        return l.filterBenMinority;
      case 'ex_servicemen':
        return l.filterBenExServicemen;
    }
    return code;
  }

  /// A grid of equal-width chips, at most [maxColumns] wide. The column count
  /// follows the width actually available (and the text scale), so narrow
  /// phones and large fonts get fewer, wider chips instead of truncated labels.
  /// Every cell in a row is the same width, so nothing reflows when the
  /// selection changes.
  Widget _group(String title, int maxColumns, List<_ChipSpec> chips) {
    if (chips.isEmpty) return const SizedBox.shrink();
    final textScale = MediaQuery.textScalerOf(context);
    // Room for a ~12 character label, the count and the chip padding.
    final minChipWidth =
        textScale.scale(12) * 12 + textScale.scale(11) * 2 + AppSpacing.md * 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = <Widget>[];
        final fit =
            ((constraints.maxWidth + AppSpacing.sm) /
                    (minChipWidth + AppSpacing.sm))
                .floor();
        final columns = fit.clamp(1, maxColumns);
        for (var i = 0; i < chips.length; i += columns) {
          final slice = chips.sublist(
            i,
            i + columns > chips.length ? chips.length : i + columns,
          );
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: c < slice.length
                          ? _chip(slice[c])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return _groupBody(title, rows);
      },
    );
  }

  Widget _groupBody(String title, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...rows,
        ],
      ),
    );
  }

  Widget _chip(_ChipSpec spec) {
    final selected = spec.selected;
    return GestureDetector(
      onTap: spec.onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${spec.count}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipSpec {
  const _ChipSpec(this.label, this.count, this.selected, this.onTap);
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
}
