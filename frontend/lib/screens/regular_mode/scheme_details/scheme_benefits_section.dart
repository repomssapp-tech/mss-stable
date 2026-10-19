import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/l10n.dart';
import '../../../models/localized_scheme.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';

String formatFunding(double amount) {
  if (amount >= 10000000) {
    return '₹${(amount / 10000000).toStringAsFixed(1)} crore';
  }
  if (amount >= 100000) {
    return '₹${(amount / 100000).toStringAsFixed(1)} lakh';
  }
  return '₹${amount.toStringAsFixed(0)}';
}

/// Content section for scheme benefits including metrics chips and overview description.
class SchemeBenefitsContent extends StatelessWidget {
  final LocalizedScheme scheme;

  const SchemeBenefitsContent({super.key, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final benefitCards = <Map<String, Object>>[
      if (scheme.subsidyPercentage != null)
        {
          "icon": Icons.percent_rounded,
          "color": const Color(0xFF047857),
          "bg": const Color(0xFFECFDF5),
          "title": context.l10n.benefitSubsidy,
          "desc": "${scheme.subsidyPercentage!.toStringAsFixed(0)}%",
        },
      if (scheme.subsidyAmount.isNotEmpty &&
          scheme.subsidyAmount.toLowerCase() != 'not specified')
        {
          "icon": Icons.payments_outlined,
          "color": const Color(0xFF1D4ED8),
          "bg": const Color(0xFFEFF6FF),
          "title": context.l10n.benefitAmount,
          "desc": scheme.subsidyAmount,
        },
      if (scheme.maxFunding != null)
        {
          "icon": Icons.account_balance_wallet_outlined,
          "color": const Color(0xFF6D28D9),
          "bg": const Color(0xFFF5F3FF),
          "title": context.l10n.benefitMaximum,
          "desc": formatFunding(scheme.maxFunding!),
        },
      if (scheme.schemeType.isNotEmpty)
        {
          "icon": Icons.category_outlined,
          "color": const Color(0xFFEA580C),
          "bg": const Color(0xFFFFEDD5),
          "title": context.l10n.benefitSupport,
          "desc": scheme.schemeType,
        },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          scheme.benefits.isEmpty
              ? CentralizedTranslator.instance.localize(
                  'Benefit details are available from the official source.',
                )
              : scheme.benefits,
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 11.5,
            height: 1.45,
          ),
        ),
        if (benefitCards.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final cardWidth = (screenWidth - 32 - 12) / 2;
              final cardHeight = cardWidth / 2;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: benefitCards.map((card) {
                    return Container(
                      width: cardWidth,
                      height: cardHeight,
                      margin: const EdgeInsets.only(
                        right: AppSpacing.md,
                        bottom: AppSpacing.xs,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: card["bg"] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            card["icon"] as IconData,
                            color: card["color"] as Color,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card["title"] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.hairline),
                                Text(
                                  card["desc"] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
