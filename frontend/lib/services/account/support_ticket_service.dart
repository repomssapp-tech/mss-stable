import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';
import '../chat/chat_log_service.dart';
import 'account_api_service.dart';
import 'app_session.dart';

/// Which support-ticket input failed client validation. The UI turns it into
/// a localized message; [SupportTicketValidationException.message] is the
/// English text for logs.
enum SupportTicketInputError {
  missingCategory,
  missingEmail,
  invalidEmail,
  missingDescription,
  descriptionTooShort,
}

/// Exception thrown when support ticket form inputs fail client validation.
class SupportTicketValidationException implements Exception {
  final SupportTicketInputError reason;
  final String message;
  const SupportTicketValidationException(this.reason, this.message);

  @override
  String toString() => message;
}

/// Exception thrown when ticket submission exceeds rate limits (client or database).
class SupportTicketRateLimitException implements Exception {
  /// Seconds left of the client-side cooldown; null when the server refused
  /// the ticket (HTTP 429).
  final int? retryAfterSeconds;
  final String message;
  const SupportTicketRateLimitException(this.message, {this.retryAfterSeconds});

  @override
  String toString() => message;
}

/// Exception thrown when the server rejects or cannot store the ticket.
class SupportTicketSubmissionException implements Exception {
  final String message;
  const SupportTicketSubmissionException(this.message);

  @override
  String toString() => message;
}

/// Service handling validation, anti-bot rate limiting, and submission
/// for user-submitted support tickets and issue reports.
class SupportTicketService {
  SupportTicketService._();
  static final SupportTicketService instance = SupportTicketService._();

  /// Cooldown between submissions in seconds to mitigate bots and rapid multi-taps.
  static const int kCooldownSeconds = 30;

  /// Shortest description the server accepts (`description: 10..5000`).
  static const int kMinDescriptionLength = 10;

  DateTime? _lastSubmittedAt;

  /// RFC 5322 compliant regex for validating email addresses.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates input fields before sending to the backend.
  void validateInputs({
    required String category,
    required String email,
    required String description,
  }) {
    if (category.trim().isEmpty) {
      throw const SupportTicketValidationException(
        SupportTicketInputError.missingCategory,
        'Please select an issue category.',
      );
    }

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw const SupportTicketValidationException(
        SupportTicketInputError.missingEmail,
        'Please enter your contact email address.',
      );
    }

    if (!_emailRegex.hasMatch(trimmedEmail)) {
      throw const SupportTicketValidationException(
        SupportTicketInputError.invalidEmail,
        'Please enter a valid email address (e.g. name@example.com).',
      );
    }

    final trimmedDescription = description.trim();
    if (trimmedDescription.isEmpty) {
      throw const SupportTicketValidationException(
        SupportTicketInputError.missingDescription,
        'Please describe the issue you are facing.',
      );
    }

    if (trimmedDescription.length < kMinDescriptionLength) {
      throw const SupportTicketValidationException(
        SupportTicketInputError.descriptionTooShort,
        'Please provide a bit more detail (at least 10 characters).',
      );
    }
  }

  /// Submits a support ticket to the backend with anti-bot rate-limiting and input validation.
  Future<void> submitTicket({
    required String category,
    required String email,
    required String description,
  }) async {
    // 1. Client-Side Validation
    validateInputs(category: category, email: email, description: description);

    // 2. Client-Side Anti-Bot / Flood Cooldown
    final now = DateTime.now();
    if (_lastSubmittedAt != null) {
      final elapsedSeconds = now.difference(_lastSubmittedAt!).inSeconds;
      if (elapsedSeconds < kCooldownSeconds) {
        final remaining = kCooldownSeconds - elapsedSeconds;
        throw SupportTicketRateLimitException(
          'Please wait $remaining seconds before submitting another ticket.',
          retryAfterSeconds: remaining,
        );
      }
    }

    // 3. Prepare the payload. The owner comes from the bearer token (or the
    //    guest token), never from the body.
    final mapped = _apiCategory(category);
    var text = description.trim();
    if (mapped.prefix.isNotEmpty) text = '${mapped.prefix}$text';
    if (text.length > 5000) text = text.substring(0, 5000);
    final payload = <String, dynamic>{
      'category': mapped.category,
      'contact_email': email.trim().toLowerCase(),
      'description': text,
    };

    // One idempotency key per submission: reused when the same payload is sent
    // again after an uncertain failure, so the server never files it twice.
    final fingerprint =
        '${payload['category']}|${payload['contact_email']}|$text';
    final key = _retryKey != null && _retryFingerprint == fingerprint
        ? _retryKey!
        : ChatLogService.generateUuidV4();
    _retryKey = key;
    _retryFingerprint = fingerprint;

    // 4. Submission
    try {
      await AccountApiService.instance.createSupportTicket(
        payload,
        idempotencyKey: key,
        signedIn: AppSession.instance.isSignedIn,
      );
      _lastSubmittedAt = DateTime.now();
      _retryKey = null;
      _retryFingerprint = null;
      debugPrint('[SupportTicketService] Support ticket created.');
    } on ApiException catch (e) {
      debugPrint(
        '[SupportTicketService] ApiException: ${e.statusCode} ${e.errorCode}',
      );
      if (e.statusCode == 429) {
        throw const SupportTicketRateLimitException(
          'Too many tickets. Please try again later.',
        );
      }
      if (e.statusCode >= 400 && e.statusCode < 500 && e.statusCode != 0) {
        // The server refused this exact submission: the next one is new.
        _retryKey = null;
        _retryFingerprint = null;
      }
      throw const SupportTicketSubmissionException(
        'Unable to submit your ticket. Please check your connection and try again.',
      );
    } catch (e) {
      debugPrint('[SupportTicketService] Unexpected error: $e');
      throw const SupportTicketSubmissionException(
        'An unexpected error occurred while submitting your ticket.',
      );
    }
  }

  String? _retryKey;
  String? _retryFingerprint;

  /// The categories the server accepts. Anything else (the feedback form's
  /// "Feedback") is filed as a General Inquiry with a prefix.
  static const Set<String> apiCategories = {
    'General Inquiry',
    'Eligibility Matcher Bug',
    'Wrong Scheme Details',
    'Feature Request',
  };

  ({String category, String prefix}) _apiCategory(String category) {
    final trimmed = category.trim();
    if (apiCategories.contains(trimmed)) return (category: trimmed, prefix: '');
    return (category: 'General Inquiry', prefix: '[$trimmed] ');
  }
}
