import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../models/scheme_extras.dart';
import '../../../models/scheme_model.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';
import '../../../utils/language_names.dart';
import '../../../utils/money_format.dart';

/// Sections built from the 2026 source fields that have no dedicated slot on
/// the older scheme page: status/deadline, fees, benefit figures, contacts,
/// official links, alternate names and related schemes. Every section hides
/// itself when the record carries no data for it, so a sparse record shows
/// nothing extra rather than empty headings.
class SchemeExtraSections extends StatelessWidget {
  const SchemeExtraSections({
    super.key,
    required this.scheme,
    required this.lang,
    required this.onOpenUrl,
    required this.resolveScheme,
    required this.onOpenScheme,
  });

  final Scheme scheme;
  final String lang;
  final Future<void> Function(String url) onOpenUrl;

  /// Looks up a related scheme by id; null when it is not in the catalog.
  final Scheme? Function(String id) resolveScheme;
  final void Function(Scheme scheme) onOpenScheme;

  @override
  Widget build(BuildContext context) {
    final extras = scheme.extras;
    if (extras.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (extras.isMachineTranslated(lang)) _TranslationNotice(lang: lang),
        _StatusCard(extras: extras, lang: lang),
        _ApplyInfoCard(extras: extras),
        _BenefitFactsCard(extras: extras, lang: lang),
        _ContactsCard(extras: extras, lang: lang, onOpenUrl: onOpenUrl),
        _LinksCard(extras: extras, lang: lang, onOpenUrl: onOpenUrl),
        _AltNamesCard(extras: extras, lang: lang),
        _RelatedCard(
          extras: extras,
          resolveScheme: resolveScheme,
          onOpenScheme: onOpenScheme,
        ),
      ],
    );
  }
}

/// Card shell. The bottom margin lives here so a section that hides itself
/// (returns `SizedBox.shrink`) leaves no gap behind.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      // ListTile children paint on the nearest Material; the decorated
      // Container above would hide them (and trips a debug assertion), so give
      // them a transparent Material surface.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: text.cardTitle.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({this.label, required this.value});

  final String? label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The label column is wide enough for a whole word in every language
          // (the Tamil word for "phone" used to break mid-word in a narrow one).
          if (label != null)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96, maxWidth: 140),
              child: Text(
                label!,
                style: text.label.copyWith(color: AppColors.textSecondary),
              ),
            ),
          if (label != null) const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 5,
            child: SelectableText(
              value,
              style: text.body.copyWith(color: AppColors.textBody),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslationNotice extends StatelessWidget {
  const _TranslationNotice({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.translate, size: 16, color: AppColors.warningOnSoft),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.schemeTranslationNotice(languageEndonym(lang)),
              style: context.text.bodySmall.copyWith(
                color: AppColors.warningOnSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _applicationStatusLabel(BuildContext context, String raw) {
  final l10n = context.l10n;
  switch (raw.toLowerCase().trim()) {
    case 'open':
      return l10n.schemeAppStatusOpen;
    case 'closed':
      return l10n.schemeAppStatusClosed;
    case 'announced':
      return l10n.schemeAppStatusAnnounced;
    case 'historical_or_superseded':
      return l10n.schemeAppStatusHistorical;
    case 'temporarily unavailable':
      return l10n.schemeAppStatusUnavailable;
    case 'unknown':
      return l10n.schemeAppStatusUnknown;
  }
  return null; // absent and unrecognised values are not shown
}

String? _procedureLabel(BuildContext context, String raw) {
  final l10n = context.l10n;
  switch (raw.toLowerCase().trim()) {
    case 'official':
      return l10n.schemeProcedureOfficial;
    case 'policy_text':
      return l10n.schemeProcedurePolicy;
    case 'secondary_web':
      return l10n.schemeProcedureSecondary;
    case 'generic':
      return l10n.schemeProcedureGeneric;
  }
  return null;
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.extras, required this.lang});

  final SchemeExtras extras;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = _applicationStatusLabel(context, extras.applicationStatus);
    final procedure = _procedureLabel(context, extras.procedureType);
    final note = extras.statusNote(lang);
    final asOf = extras.statusAsOf;
    final deadline = extras.deadline;
    if (status == null &&
        procedure == null &&
        note.isEmpty &&
        deadline.isEmpty) {
      return const SizedBox.shrink();
    }
    return _Card(
      title: l10n.schemeSectionStatus,
      children: [
        if (status != null) _Line(value: l10n.schemeApplicationStatus(status)),
        if (note.isNotEmpty) _Line(value: note),
        if (deadline.isNotEmpty)
          _Line(label: l10n.schemeDeadline, value: deadline),
        if (procedure != null) _Line(value: procedure),
        if (asOf.isNotEmpty) _Line(value: l10n.schemeStatusAsOf(asOf)),
      ],
    );
  }
}

class _ApplyInfoCard extends StatelessWidget {
  const _ApplyInfoCard({required this.extras});

  final SchemeExtras extras;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fees = extras.fees;
    final prerequisite = extras.prerequisite;
    if (fees.isEmpty && prerequisite.isEmpty) return const SizedBox.shrink();
    return _Card(
      title: l10n.schemeSectionApplyInfo,
      children: [
        if (fees.isNotEmpty) _Line(label: l10n.schemeFees, value: fees),
        if (prerequisite.isNotEmpty)
          _Line(label: l10n.schemePrerequisite, value: prerequisite),
      ],
    );
  }
}

class _BenefitFactsCard extends StatelessWidget {
  const _BenefitFactsCard({required this.extras, required this.lang});

  final SchemeExtras extras;
  final String lang;

  String _label(BuildContext context, String key) {
    final l10n = context.l10n;
    switch (key) {
      case 'max_inr':
      case 'max_percent_pa':
        return l10n.schemeFactMax;
      case 'min_inr':
        return l10n.schemeFactMin;
      case 'amount_inr':
        return l10n.schemeFactAmount;
      case 'percent':
      case 'value_percent':
        return l10n.schemeFactPercent;
      case 'tenure_months':
        return l10n.schemeFactTenure;
      case 'interest_rate_percent':
        return l10n.schemeFactInterest;
      case 'coverage_percent':
        return l10n.schemeFactCoverage;
      case 'max_cover_inr':
        return l10n.schemeFactMaxCover;
      case 'fee_percent':
        return l10n.schemeFactFee;
      case 'moratorium_months':
        return l10n.schemeFactMoratorium;
      case 'duration_months':
        return l10n.schemeFactDuration;
    }
    return SchemeExtras.humanize(key);
  }

  String _value(BuildContext context, String key, num v) {
    if (key.endsWith('_inr')) return formatInr(v, decimals: 0);
    if (key.endsWith('percent') || key.endsWith('percent_pa')) return '$v%';
    if (key.endsWith('_months')) {
      return context.l10n.schemeMonthsValue(v.toInt());
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final facts = extras.benefitFacts(lang);
    if (facts.isEmpty) return const SizedBox.shrink();
    final text = context.text;
    return _Card(
      title: context.l10n.schemeSectionBenefitFacts,
      children: [
        for (final fact in facts) ...[
          if (fact.type.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                CentralizedTranslator.instance.localizeTagFor(
                  lang,
                  SchemeExtras.humanize(fact.type),
                ),
                style: text.label.copyWith(color: AppColors.primaryStrong),
              ),
            ),
          for (final m in fact.metrics)
            _Line(
              label: _label(context, m.key),
              value: _value(context, m.key, m.value),
            ),
          for (final note in fact.notes) _Line(value: note),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({
    required this.extras,
    required this.lang,
    required this.onOpenUrl,
  });

  final SchemeExtras extras;
  final String lang;
  final Future<void> Function(String url) onOpenUrl;

  String _label(BuildContext context, String key) {
    final l10n = context.l10n;
    switch (key) {
      case 'phone':
        return l10n.schemeContactPhone;
      case 'helpline':
        return l10n.schemeContactHelpline;
      case 'email':
        return l10n.schemeContactEmail;
      case 'website':
        return l10n.schemeContactWebsite;
      case 'office':
        return l10n.schemeContactOffice;
      case 'address':
        return l10n.schemeContactAddress;
      case 'hours':
        return l10n.schemeContactHours;
    }
    return SchemeExtras.humanize(key);
  }

  @override
  Widget build(BuildContext context) {
    final contacts = extras.contacts(lang);
    if (contacts.isEmpty) return const SizedBox.shrink();
    return _Card(
      title: context.l10n.schemeSectionContacts,
      children: [
        for (final c in contacts)
          c.key == 'website'
              ? InkWell(
                  onTap: () => onOpenUrl(c.value),
                  child: _Line(label: _label(context, c.key), value: c.value),
                )
              : _Line(label: _label(context, c.key), value: c.value),
      ],
    );
  }
}

class _LinksCard extends StatelessWidget {
  const _LinksCard({
    required this.extras,
    required this.lang,
    required this.onOpenUrl,
  });

  final SchemeExtras extras;
  final String lang;
  final Future<void> Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final links = extras.links(lang);
    if (links.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    String label(({String kind, String url, String? title}) link) {
      final kindLabel = switch (link.kind) {
        'apply' => l10n.schemeLinkApply,
        'guidelines' => l10n.schemeLinkGuidelines,
        'portal' => l10n.schemeLinkPortal,
        'portalLogin' => l10n.schemeLinkPortalLogin,
        'portalServices' => l10n.schemeLinkPortalServices,
        _ => l10n.schemeLinkInfo,
      };
      final title = link.title;
      return title == null ? kindLabel : '$kindLabel · $title';
    }

    return _Card(
      title: l10n.schemeSectionLinks,
      children: [
        for (final link in links)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.open_in_new,
              size: 18,
              color: AppColors.primary,
            ),
            title: Text(
              label(link),
              style: context.text.body.copyWith(color: AppColors.primary),
            ),
            subtitle: Text(
              link.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            onTap: () => onOpenUrl(link.url),
          ),
      ],
    );
  }
}

class _AltNamesCard extends StatelessWidget {
  const _AltNamesCard({required this.extras, required this.lang});

  final SchemeExtras extras;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final names = extras.altNames(lang);
    if (names.isEmpty) return const SizedBox.shrink();
    return _Card(
      title: context.l10n.schemeSectionAltNames,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final n in names)
              Chip(
                label: Text(
                  n,
                  style: context.text.bodySmall.copyWith(
                    color: AppColors.textBody,
                  ),
                ),
                backgroundColor: AppColors.surfaceMuted,
                side: BorderSide.none,
              ),
          ],
        ),
      ],
    );
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({
    required this.extras,
    required this.resolveScheme,
    required this.onOpenScheme,
  });

  final SchemeExtras extras;
  final Scheme? Function(String id) resolveScheme;
  final void Function(Scheme scheme) onOpenScheme;

  @override
  Widget build(BuildContext context) {
    final related = extras.relatedIds
        .map(resolveScheme)
        .whereType<Scheme>()
        .toList(growable: false);
    if (related.isEmpty) return const SizedBox.shrink();
    return _Card(
      title: context.l10n.schemeSectionRelated,
      children: [
        for (final s in related)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              LocalizedScheme.fromScheme(
                s,
                Localizations.localeOf(context).languageCode,
              ).name,
              style: context.text.body.copyWith(color: AppColors.primary),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.iconMuted,
            ),
            onTap: () => onOpenScheme(s),
          ),
      ],
    );
  }
}
