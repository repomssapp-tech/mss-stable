/// What the primary action on the scheme details screen should do.
enum SchemeActionKind {
  /// A direct application link whose availability the catalog confirms.
  apply,

  /// An official page that describes the scheme; it does not imply that
  /// applications are open.
  officialInfo,

  /// No usable link.
  none,
}

class SchemeActionTarget {
  const SchemeActionTarget(this.kind, [this.url = '']);

  static const none = SchemeActionTarget(SchemeActionKind.none);

  final SchemeActionKind kind;
  final String url;

  bool get isEnabled => kind != SchemeActionKind.none;
}

bool isSafeWebUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

/// Chooses between a direct Apply action and an Official information action.
///
/// Apply needs both an application destination and an explicit `open`
/// application status. A valid URL alone never means applications are open,
/// and an unknown or missing status never means they are closed: those
/// schemes still expose their official information link.
SchemeActionTarget resolveSchemeAction({
  required String applicationUrl,
  required String schemeUrl,
  required String officialWebsite,
  required String applicationStatus,
}) {
  final apply = applicationUrl.trim();
  if (isSafeWebUrl(apply) &&
      applicationStatus.toLowerCase().trim() == 'open') {
    return SchemeActionTarget(SchemeActionKind.apply, apply);
  }
  for (final candidate in [schemeUrl, officialWebsite, applicationUrl]) {
    final url = candidate.trim();
    if (isSafeWebUrl(url)) {
      return SchemeActionTarget(SchemeActionKind.officialInfo, url);
    }
  }
  return SchemeActionTarget.none;
}
