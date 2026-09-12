import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/l10n.dart';
import '../../../models/scheme_model.dart';

/// Content section for scheme required services (e.g. GST registration, Udyam certificate).
class SchemeServicesContent extends StatelessWidget {
  final List<SchemeService> services;

  const SchemeServicesContent({
    super.key,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Text(
        context.l10n.noServicesRequiredMsg,
        style: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 11.0,
        ),
      );
    }

    return Column(
      children: services.map((service) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFCCFBF1),
            child: Icon(
              Icons.support_agent_outlined,
              color: Color(0xFF0F766E),
              size: 18,
            ),
          ),
          title: Text(
            service.name,
            style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            [
              service.category,
              service.description,
            ].where((value) => value.isNotEmpty).join(' • '),
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 10.0,
              height: 1.35,
            ),
          ),
          trailing: service.mandatory
              ? const Icon(Icons.check_circle, color: Color(0xFF0F766E))
              : null,
        );
      }).toList(),
    );
  }
}
