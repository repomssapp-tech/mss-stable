import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_state_provider.dart';
import '../../../services/catalog/centralized_translator.dart';
import '../../../utils/app_spacing.dart';

class GovtInteractivePanel extends StatefulWidget {
  final Color iconColor;

  const GovtInteractivePanel({
    super.key,
    required this.iconColor,
  });

  @override
  State<GovtInteractivePanel> createState() => _GovtInteractivePanelState();
}

class _GovtInteractivePanelState extends State<GovtInteractivePanel> {
  int _selectedGovtTab = 0; // 0: Central, 1: State, 2: District

  @override
  Widget build(BuildContext context) {
    final isTa =
        Provider.of<AppProvider>(context, listen: false).selectedLanguage ==
        'ta';
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
              isTa
                  ? CentralizedTranslator.instance.translate(
                      'Government Authorities Tree',
                    )
                  : 'Government Authorities Tree',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _buildGovtTabHeader(
                  0,
                  isTa
                      ? CentralizedTranslator.instance.translate('Central')
                      : 'Central',
                ),
                _buildGovtTabHeader(
                  1,
                  isTa
                      ? CentralizedTranslator.instance.translate('State')
                      : 'State',
                ),
                _buildGovtTabHeader(
                  2,
                  isTa
                      ? CentralizedTranslator.instance.translate('District')
                      : 'District',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildGovtTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildGovtTabHeader(int tabIndex, String title) {
    final isSelected = tabIndex == _selectedGovtTab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGovtTab = tabIndex;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? widget.iconColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? widget.iconColor : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGovtTabContent() {
    final isTa =
        Provider.of<AppProvider>(context, listen: false).selectedLanguage ==
        'ta';
    String name = '';
    String roles = '';
    String details = '';

    if (_selectedGovtTab == 0) {
      name = 'Ministry of Micro, Small and Medium Enterprises (M/o MSME)';
      roles =
          '• Formulation and administration of rules, regulations, and laws.\n• Designs apex developmental schemes (PMEGP, CGTMSE, SFURTI).\n• Coordinates with other central ministries for national policy.';
      details =
          'Located in Udyog Bhawan, New Delhi. Operates MSME Development Institutes (MSME-DI) nationwide.';
    } else if (_selectedGovtTab == 1) {
      name = 'State Directorate of Industries / Commissionerate';
      roles =
          '• Implements central and state industrial policies.\n• Handles state capital incentives, interest subsidies, and power tariff concessions.\n• Coordinates development of industrial parks and estates.';
      details =
          'In Tamil Nadu, this is the Department of Industries and Commerce (MSME Department).';
    } else {
      name = 'District Industries Centre (DIC)';
      roles =
          '• Nodal agency at the grass-roots level providing Udyam registration assistance.\n• Recommends loan approvals to banks under PMEGP.\n• Performs spot verification of industrial units for subsidy release.\n• Resolves local vendor issues via Micro & Small Enterprises Facilitation Council (MSEFC).';
      details =
          'Each district in India has a DIC, headed by a General Manager.';
    }

    if (isTa) {
      name = CentralizedTranslator.instance.translate(name);
      roles = CentralizedTranslator.instance.translate(roles);
      details = CentralizedTranslator.instance.translate(details);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            roles,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF475569),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: AppSpacing.tight),
              Expanded(
                child: Text(
                  details,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
