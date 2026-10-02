import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/l10n.dart';
import '../../../services/catalog/scheme_repository.dart';
import '../../../utils/app_spacing.dart';
import '../msme_module_details_screen.dart';
import '../search_results_screen.dart';

class HomeJourneySection extends StatelessWidget {
  const HomeJourneySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.whatWouldYouLikeToDoToday,
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: [
              _buildJourneyActionCard(
                context: context,
                title: context.l10n.exportSupport,
                icon: Icons.public_rounded,
                moduleId: 'export',
              ),
              _buildJourneyActionCard(
                context: context,
                title: context.l10n.growBusiness,
                icon: Icons.trending_up_rounded,
                categoryName: 'Business & MSME',
              ),
              _buildJourneyActionCard(
                context: context,
                title: context.l10n.registerUdyam,
                icon: Icons.app_registration_rounded,
                moduleId: 'udyam',
              ),
              _buildJourneyActionCard(
                context: context,
                title: context.l10n.findFunding,
                icon: Icons.currency_rupee_rounded,
                categoryName: 'Business Loans & Credit',
              ),
              _buildJourneyActionCard(
                context: context,
                title: context.l10n.startABusiness,
                icon: Icons.rocket_launch_rounded,
                categoryName: 'Startup',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    String? moduleId,
    String? categoryName,
  }) {
    String formattedTitle = title;
    if (title.contains(' ')) {
      formattedTitle = title.replaceFirst(' ', '\n');
    }

    return GestureDetector(
      onTap: () async {
        // Route on the language-stable moduleId / categoryName, never the
        // localized `title` -- in Tamil a title like "உத்யம் பதிவு" contains
        // no "udyam"/"export" substring, so the old checks silently fell
        // through and every card returned the same generic fallback list.

        // 1. Register Udyam -> interactive Udyam Registration module
        if (moduleId == 'udyam') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MSMEModuleDetailsScreen(
                moduleId: 'udyam',
                title: context.l10n.registerUdyam,
                description: context.l10n.udyamModuleDescription,
                icon: Icons.app_registration_rounded,
                iconColor: const Color(0xFF2563EB),
                themeColor: const Color(0xFFEFF6FF),
              ),
            ),
          );
          return;
        }

        // 2. Export Support -> Export Readiness module
        if (moduleId == 'export') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MSMEModuleDetailsScreen(
                moduleId: 'export',
                title: context.l10n.exportSupport,
                description: context.l10n.exportModuleDescription,
                icon: Icons.public_rounded,
                iconColor: const Color(0xFF047857),
                themeColor: const Color(0xFFECFDF5),
              ),
            ),
          );
          return;
        }

        final schemes = await SchemeRepository.instance.getSchemesByCategory(
          categoryName ?? title,
        );
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SearchResultsScreen(
              title: title,
              type: 'category',
              initialSchemes: schemes,
            ),
          ),
        );
      },
      child: Container(
        width: 88,
        height: 112,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 24),
            const SizedBox(height: AppSpacing.tight),
            Expanded(
              child: Center(
                child: Text(
                  formattedTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
