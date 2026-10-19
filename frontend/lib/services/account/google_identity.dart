import 'rest_auth_service.dart';

/// Pure helpers for pulling Google account details out of the signed-in
/// backend [AuthUser] (the server stores the Google name and picture).
///
/// Unit coverage: `test/google_profile_photo_test.dart`.

/// The Google account profile image URL, or `''` if none is present.
String extractGooglePhoto(AuthUser? user) => user?.pictureUrl?.trim() ?? '';

/// The Google account display name, or `''` if none is present.
String extractGoogleName(AuthUser? user) => user?.name.trim() ?? '';
