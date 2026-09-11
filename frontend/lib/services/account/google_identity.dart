import 'package:supabase_flutter/supabase_flutter.dart';

/// Pure helpers for pulling Google account details out of a Supabase Auth
/// [User] (checking `userMetadata` first, then linked `identities`).
///
/// Extracted verbatim from `AppProvider` — behaviour is unchanged. Unit
/// coverage: `test/google_profile_photo_test.dart`.

String _firstNonEmptyString(User? user, List<String> keys) {
  if (user == null) return '';
  final meta = user.userMetadata;
  if (meta != null) {
    for (final key in keys) {
      final val = meta[key];
      if (val is String && val.trim().isNotEmpty) return val.trim();
    }
  }
  final identities = user.identities;
  if (identities != null) {
    for (final identity in identities) {
      final idData = identity.identityData;
      if (idData == null) continue;
      for (final key in keys) {
        final val = idData[key];
        if (val is String && val.trim().isNotEmpty) return val.trim();
      }
    }
  }
  return '';
}

/// The Google account profile image URL, or `''` if none is present.
String extractGooglePhoto(User? user) => _firstNonEmptyString(
  user,
  const ['avatar_url', 'picture', 'photo_url', 'avatarUrl'],
);

/// The Google account display name, or `''` if none is present.
String extractGoogleName(User? user) => _firstNonEmptyString(
  user,
  const ['full_name', 'name', 'user_name'],
);
