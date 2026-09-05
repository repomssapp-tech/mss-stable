import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/mss_catalog_bundle.dart';

/// 2.7 (audit_fix.md): a subtle indicator of catalog data currency, so a
/// user can tell "no match" apart from "this device's local catalog is
/// old" -- worded as data currency, not degradation, since offline-first
/// is the intended design here, not something to apologize for.
class CatalogFreshnessFooter extends StatelessWidget {
  const CatalogFreshnessFooter({super.key, this.isTa = false});

  final bool isTa;

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MssCatalogBundle>(
      future: MssCatalogBundle.load(),
      builder: (context, snapshot) {
        final bundle = snapshot.data;
        if (bundle == null) return const SizedBox.shrink();

        final dateText = bundle.releasedAt != null
            ? _formatDate(bundle.releasedAt!.toLocal())
            : null;
        final label = isTa
            ? 'உள்ளூர் பட்டியல் பதிப்பு ${bundle.releaseTag}'
                '${dateText != null ? ' • $dateText' : ''}'
            : 'Local catalog v${bundle.releaseTag}'
                '${dateText != null ? ' • updated $dateText' : ''}';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
        );
      },
    );
  }
}
