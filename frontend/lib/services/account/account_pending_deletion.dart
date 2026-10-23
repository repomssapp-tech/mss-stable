import '../network/api_exception.dart';

/// A sign-in reached an account the user deleted within the last 30 days.
///
/// The server answers `403 ACCOUNT_PENDING_DELETION` and issues no session.
/// [restoreToken] (valid 10 minutes, one use) reactivates the account through
/// `POST /v1/auth/restore`, but only after the user agrees.
class AccountPendingDeletion implements Exception {
  const AccountPendingDeletion({
    required this.restoreToken,
    this.deletedAt,
    this.purgeAfter,
  });

  final String restoreToken;
  final DateTime? deletedAt;

  /// When the account and its data are permanently removed.
  final DateTime? purgeAfter;

  static const errorCode = 'ACCOUNT_PENDING_DELETION';

  /// The pending deletion carried by [error], or null for any other failure.
  static AccountPendingDeletion? fromError(Object error) {
    if (error is! ApiException || error.errorCode != errorCode) return null;
    final token = error.fields?['restore_token'];
    if (token is! String || token.isEmpty) return null;
    DateTime? date(String key) =>
        DateTime.tryParse(error.fields?[key]?.toString() ?? '')?.toLocal();
    return AccountPendingDeletion(
      restoreToken: token,
      deletedAt: date('deleted_at'),
      purgeAfter: date('purge_after'),
    );
  }

  @override
  String toString() => 'AccountPendingDeletion(purgeAfter: $purgeAfter)';
}
