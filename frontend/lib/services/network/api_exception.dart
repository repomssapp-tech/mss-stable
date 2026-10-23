/// Typed exceptions thrown by the MSS REST API Client.
class ApiException implements Exception {
  final int statusCode;
  final String errorCode;
  final String message;
  final List<dynamic>? details;

  /// Object-valued `details` from the error body, such as the restore token of
  /// `ACCOUNT_PENDING_DELETION`. Null when the body has none or a list.
  final Map<String, dynamic>? fields;
  final int? retryAfterSeconds;
  final String? requestId;

  const ApiException({
    required this.statusCode,
    required this.errorCode,
    required this.message,
    this.details,
    this.fields,
    this.retryAfterSeconds,
    this.requestId,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isStaleVersion =>
      statusCode == 412 || errorCode == 'PROFILE_VERSION_CONFLICT';
  bool get isIfMatchRequired =>
      statusCode == 428 || errorCode == 'IF_MATCH_REQUIRED';
  bool get isRateLimited => statusCode == 429;
  bool get isServiceUnavailable => statusCode == 503;

  @override
  String toString() {
    final buffer = StringBuffer('ApiException($statusCode: $errorCode');
    if (message.isNotEmpty) buffer.write(' - $message');
    if (details != null && details!.isNotEmpty) {
      buffer.write(', details: $details');
    }
    if (requestId != null) buffer.write(', req: $requestId');
    if (retryAfterSeconds != null) {
      buffer.write(', retryAfter: ${retryAfterSeconds}s');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
