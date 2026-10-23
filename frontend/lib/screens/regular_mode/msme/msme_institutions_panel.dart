import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

class InstitutionsInteractivePanel extends StatefulWidget {
  final Color iconColor;

  const InstitutionsInteractivePanel({super.key, required this.iconColor});

  @override
  State<InstitutionsInteractivePanel> createState() =>
      _InstitutionsInteractivePanelState();
}

class _InstitutionsInteractivePanelState
    extends State<InstitutionsInteractivePanel> {
  String _institutionsSearch = '';
  final List<Map<String, dynamic>> _institutions = [
    {
      'name': 'SIDBI',
      'fullName': 'Small Industries Development Bank of India',
      'role':
          'Principal financial institution for MSME promotion, financing, and development.',
      'services':
          'Direct lending, venture capital, refinance to banks, startup funding.',
      'schemes':
          'SMILE (SIDBI Make in India Loan for Enterprises), ARISE, Speed Plus.',
    },
    {
      'name': 'NSIC',
      'fullName': 'National Small Industries Corporation',
      'role':
          'Government enterprise facilitating marketing, technology, and raw material support.',
      'services':
          'Raw Material Assistance Scheme, Single Point Registration Scheme for govt tenders.',
      'schemes': 'Consortia and Tender Marketing, Raw Material Distribution.',
    },
    {
      'name': 'DIC',
      'fullName': 'District Industries Centre',
      'role':
          'District-level nodal agency providing single-window assistance for setting up MSMEs.',
      'services':
          'Udyam registration support, state subsidy verification, local clearances, PMEGP implementation.',
      'schemes':
          'Prime Minister\'s Employment Generation Programme (PMEGP), State-specific capital subsidies.',
    },
    {
      'name': 'KVIC',
      'fullName': 'Khadi and Village Industries Commission',
      'role':
          'Nodal agency implementing rural employment and cottage industry schemes.',
      'services':
          'Subsidies, training centers, khadi production support, sales outlets.',
      'schemes':
          'PMEGP (Nodal Agency), Scheme of Fund for Regeneration of Traditional Industries (SFURTI).',
    },
    {
      'name': 'TIIC',
      'fullName': 'Tamil Nadu Industrial Investment Corporation',
      'role':
          'State-level financial institution providing term loans to MSMEs in Tamil Nadu.',
      'services': 'Term loans for land, building, and machinery acquisition.',
      'schemes':
          'NEEDS (New Entrepreneur cum Enterprise Development Scheme), Capital Subsidy Scheme.',
    },
    {
      'name': 'StartupTN / FaMeTN',
      'fullName': 'Startup Tamil Nadu & Facilitating MSMEs Tamil Nadu',
      'role':
          'Nodal agencies for fostering startup ecosystem and facilitating MSMEs in Tamil Nadu.',
      'services':
          'TANSEED seed fund, incubator support, marketing assistance, buyer-seller meets.',
      'schemes':
          'TANSEED Grants, MSME Trade Portal Assistance, Cluster Development.',
    },
    {
      'name': 'SIPCOT',
      'fullName': 'State Industries Promotion Corporation of Tamil Nadu',
      'role': 'Industrial infrastructure development agency.',
      'services':
          'Allotment of plots/sheds in industrial parks, basic infrastructure provisions.',
      'schemes':
          'Industrial Park Infrastructure Support, Environmental Clearance Guidance.',
    },
  ];

  Widget _buildExpansionItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 12,
              decoration: BoxDecoration(
                color: widget.iconColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.tight),
            Flexible(
              child: Text(
                label,
                softWrap: true,
                style: AppGoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppGoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF1E293B),
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _institutions.where((inst) {
      final text = _institutionsSearch.toLowerCase();
      final translator = CentralizedTranslator.instance;
      // Match the English constants and the localized text the card shows.
      return [
        inst['name'],
        inst['fullName'],
        inst['role'],
        translator.localize(inst['fullName']),
        translator.localize(inst['role']),
        translator.localize(inst['services']),
        translator.localize(inst['schemes']),
      ].any((field) => field.toString().toLowerCase().contains(text));
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.msmeSearchSupportInstitutions,
              style: AppGoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 40,
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _institutionsSearch = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: context.l10n.msmeSearchInstitutionsHint,
                  hintStyle: AppGoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Inline rather than a small nested scroller: the card grows with
            // its content and the page scrolls, so institutions are easy to
            // look up.
            Column(
              children: [
                for (final inst in filtered)
                  Builder(
                    builder: (context) {
                      final roleText = CentralizedTranslator.instance.localize(
                        inst['role'],
                      );
                      final servicesText = CentralizedTranslator.instance
                          .localize(inst['services']);
                      final schemesText = CentralizedTranslator.instance
                          .localize(inst['schemes']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: Text(
                              inst['name'],
                              style: AppGoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: widget.iconColor,
                              ),
                            ),
                            subtitle: Text(
                              CentralizedTranslator.instance.localize(
                                inst['fullName'],
                              ),
                              style: AppGoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            childrenPadding: const EdgeInsets.all(
                              AppSpacing.md,
                            ),
                            children: [
                              _buildExpansionItem(
                                context.l10n.msmeRoleLabel,
                                roleText,
                              ),
                              const SizedBox(height: AppSpacing.tight),
                              _buildExpansionItem(
                                context.l10n.msmeKeyServicesLabel,
                                servicesText,
                              ),
                              const SizedBox(height: AppSpacing.tight),
                              _buildExpansionItem(
                                context.l10n.msmeTopSchemesLabel,
                                schemesText,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
