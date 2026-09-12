import '../../../models/mss_entity.dart';
import '../mss_catalog_bundle.dart';
import 'scheme_adapter_text_utils.dart';

/// Immutable container holding resolved benefits, funding metrics, and linked
/// finance/tax/knowledge products for a scheme.
class SchemeBenefitsData {
  final double? maxFunding;
  final double? minFunding;
  final double? subsidyPercentage;
  final double? interestSubventionRate;
  final String subsidyAmountText;
  final String rawBenefitsDisplayText;
  final String benefitsTa;
  final List<String> benefitTypesList;
  final String capitalSubsidyDetails;
  final String interestSubventionDetails;
  final String marginMoneyDetails;
  final String loanGuaranteeDetails;
  final List<String> financeProductsSummary;
  final List<String> taxExemptionsSummary;
  final List<String> applicableTaxesList;
  final List<String> knowledgeGuidanceList;

  const SchemeBenefitsData({
    required this.maxFunding,
    required this.minFunding,
    required this.subsidyPercentage,
    required this.interestSubventionRate,
    required this.subsidyAmountText,
    required this.rawBenefitsDisplayText,
    required this.benefitsTa,
    required this.benefitTypesList,
    required this.capitalSubsidyDetails,
    required this.interestSubventionDetails,
    required this.marginMoneyDetails,
    required this.loanGuaranteeDetails,
    required this.financeProductsSummary,
    required this.taxExemptionsSummary,
    required this.applicableTaxesList,
    required this.knowledgeGuidanceList,
  });
}

/// Resolves benefits, subsidies, loans, concessions, and linked finance/tax/knowledge
/// items for a scheme entity.
class SchemeBenefitsResolver {
  SchemeBenefitsResolver._();

  static SchemeBenefitsData resolve(
    MssEntity entity,
    MssCatalogBundle bundle, {
    required String overviewEn,
    required String langCode,
  }) {
    final content = entity.content;
    final benefitsObj = (content['benefits'] as Map<String, dynamic>?) ?? {};

    // ── 5. Benefits & Funding Breakdown ────────────────────────────────
    double? maxFunding;
    double? minFunding;
    double? subsidyPercentage;
    double? interestSubventionRate;
    String subsidyAmountText = '';
    String benefitsText = '';
    String benefitsTa = '';
    final benefitsRaw =
        benefitsObj['summary'] ??
        benefitsObj['description'] ??
        content['benefits'] ??
        content['benefitsText'];
    if (benefitsRaw is Map<String, dynamic>) {
      final benefitsEn = (benefitsRaw['en'] as String? ?? '').trim();
      benefitsTa = (benefitsRaw['ta'] as String? ?? '').trim();
      benefitsText = benefitsEn.isNotEmpty ? benefitsEn : benefitsTa;
    } else if (benefitsRaw is String) {
      benefitsText = benefitsRaw;
    }
    if (benefitsTa.isEmpty) {
      benefitsTa = entity.getLocalizedAttribute('benefitsText', 'ta');
    }
    if (benefitsTa.isEmpty) {
      benefitsTa = entity.getLocalizedAttribute('benefits', 'ta');
    }

    if (benefitsText.isEmpty) {
      final bTextEn = entity.getLocalizedAttribute('benefitsText', 'en');
      if (bTextEn.isNotEmpty) {
        benefitsText = bTextEn;
      } else {
        benefitsText =
            'Provides financial assistance, subsidies, or institutional support for eligible applicants.';
      }
    }

    final capSubsidy = benefitsObj['capitalSubsidy'] as Map<String, dynamic>?;
    final intSubvention =
        benefitsObj['interestSubvention'] as Map<String, dynamic>?;
    final marginMoney = benefitsObj['marginMoney'] as Map<String, dynamic>?;
    final loanGuarantee = benefitsObj['guarantee'] as Map<String, dynamic>?;

    if (capSubsidy != null) {
      if (capSubsidy['maxAmountInr'] != null) {
        maxFunding = (capSubsidy['maxAmountInr'] as num).toDouble();
      }
      if (capSubsidy['minAmountInr'] != null) {
        minFunding = (capSubsidy['minAmountInr'] as num).toDouble();
      }
      if (capSubsidy['percentage'] != null) {
        subsidyPercentage = (capSubsidy['percentage'] as num).toDouble();
      }
      if (capSubsidy['maxText'] != null) {
        subsidyAmountText = capSubsidy['maxText'] as String;
      }
    }
    if (intSubvention != null) {
      if (intSubvention['percentage'] != null) {
        interestSubventionRate = (intSubvention['percentage'] as num)
            .toDouble();
      }
      if (intSubvention['rate'] != null) {
        interestSubventionRate ??= (intSubvention['rate'] as num).toDouble();
      }
    }

    final benefitTypesList =
        SchemeAdapterTextUtils.asList(
          benefitsObj['benefitTypes'],
        )?.map((e) => e.toString()).toList() ??
        [];
    final capitalSubsidyDetails = capSubsidy != null
        ? SchemeAdapterTextUtils.getLocalizedText(
            capSubsidy['description'] ?? capSubsidy['maxText'],
            langCode,
          )
        : '';
    final interestSubventionDetails = intSubvention != null
        ? SchemeAdapterTextUtils.getLocalizedText(
            intSubvention['description'] ?? intSubvention['text'],
            langCode,
          )
        : '';
    final marginMoneyDetails = marginMoney != null
        ? SchemeAdapterTextUtils.getLocalizedText(
            marginMoney['description'] ?? marginMoney['text'],
            langCode,
          )
        : '';
    final loanGuaranteeDetails = loanGuarantee != null
        ? SchemeAdapterTextUtils.getLocalizedText(
            loanGuarantee['description'] ?? loanGuarantee['text'],
            langCode,
          )
        : '';

    final rawBenefitsDisplayText = benefitsText.isNotEmpty
        ? benefitsText
        : overviewEn;

    // ── 9. Graph Linking: Finance, Tax, Knowledge ─────────────────────
    final financeProducts = bundle.getFinanceProductsForScheme(entity);
    final financeProductsSummary = financeProducts
        .map(
          (f) =>
              '${f.getLocalizedName(langCode)} - ${f.content['summary'] ?? f.code}',
        )
        .toList();

    for (final fin in financeProducts) {
      final amountObj = fin.content['amount'] as Map<String, dynamic>?;
      if (amountObj != null) {
        if (amountObj['maxInr'] != null) {
          maxFunding ??= (amountObj['maxInr'] as num).toDouble();
        }
        if (amountObj['minInr'] != null) {
          minFunding ??= (amountObj['minInr'] as num).toDouble();
        }
        if (subsidyAmountText.isEmpty && amountObj['maxText'] != null) {
          subsidyAmountText = amountObj['maxText'] as String;
        }
      }
      final intRateObj = fin.content['interestRate'] as Map<String, dynamic>?;
      if (intRateObj != null && intRateObj['percent'] != null) {
        interestSubventionRate ??= (intRateObj['percent'] as num).toDouble();
      }
    }

    final taxProvisions = bundle.getTaxProvisionsForScheme(entity);
    final taxExemptionsSummary = taxProvisions
        .map((t) => '${t.getLocalizedName(langCode)} (${t.code})')
        .toList();
    final applicableTaxesList = taxProvisions
        .map((t) => (t.content['taxType'] as String?) ?? 'Income Tax')
        .toSet()
        .toList();

    final knowledgeItems = bundle.getKnowledgeItemsForScheme(entity);
    final knowledgeGuidanceList = knowledgeItems
        .map(
          (k) =>
              '${k.getLocalizedName(langCode)}: ${k.content['summary'] ?? ""}',
        )
        .toList();

    return SchemeBenefitsData(
      maxFunding: maxFunding,
      minFunding: minFunding,
      subsidyPercentage: subsidyPercentage,
      interestSubventionRate: interestSubventionRate,
      subsidyAmountText: subsidyAmountText,
      rawBenefitsDisplayText: rawBenefitsDisplayText,
      benefitsTa: benefitsTa,
      benefitTypesList: benefitTypesList,
      capitalSubsidyDetails: capitalSubsidyDetails,
      interestSubventionDetails: interestSubventionDetails,
      marginMoneyDetails: marginMoneyDetails,
      loanGuaranteeDetails: loanGuaranteeDetails,
      financeProductsSummary: financeProductsSummary,
      taxExemptionsSummary: taxExemptionsSummary,
      applicableTaxesList: applicableTaxesList,
      knowledgeGuidanceList: knowledgeGuidanceList,
    );
  }
}
