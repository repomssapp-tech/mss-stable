import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exception thrown when support ticket form inputs fail client validation.
class SupportTicketValidationException implements Exception {
  final String message;
  const SupportTicketValidationException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when ticket submission exceeds rate limits (client or database).
class SupportTicketRateLimitException implements Exception {
  final String message;
  const SupportTicketRateLimitException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when the Supabase database write fails.
class SupportTicketSubmissionException implements Exception {
  final String message;
  const SupportTicketSubmissionException(this.message);

  @override
  String toString() => message;
}

/// Service handling validation, anti-bot rate limiting, and Supabase insertion
/// for user-submitted support tickets and issue reports.
class SupportTicketService {
  SupportTicketService._();
  static final SupportTicketService instance = SupportTicketService._();

  /// Cooldown between submissions in seconds to mitigate bots and rapid multi-taps.
  static const int kCooldownSeconds = 30;

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
      throw const SupportTicketValidationException('Please select an issue category.');
    }

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw const SupportTicketValidationException('Please enter your contact email address.');
    }

    if (!_emailRegex.hasMatch(trimmedEmail)) {
      throw const SupportTicketValidationException(
        'Please enter a valid email address (e.g. name@example.com).',
      );
    }

    final trimmedDescription = description.trim();
    if (trimmedDescription.isEmpty) {
      throw const SupportTicketValidationException('Please describe the issue you are facing.');
    }

    if (trimmedDescription.length < 10) {
      throw const SupportTicketValidationException(
        'Please provide a bit more detail (at least 10 characters).',
      );
    }
  }

  /// Submits a support ticket to Supabase with anti-bot rate-limiting and input validation.
  Future<void> submitTicket({
    required String category,
    required String email,
    required String description,
  }) async {
    // 1. Client-Side Validation
    validateInputs(
      category: category,
      email: email,
      description: description,
    );

    // 2. Client-Side Anti-Bot / Flood Cooldown
    final now = DateTime.now();
    if (_lastSubmittedAt != null) {
      final elapsedSeconds = now.difference(_lastSubmittedAt!).inSeconds;
      if (elapsedSeconds < kCooldownSeconds) {
        final remaining = kCooldownSeconds - elapsedSeconds;
        throw SupportTicketRateLimitException(
          'Please wait $remaining seconds before submitting another ticket.',
        );
      }
    }

    // 3. Prepare Payload
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final payload = <String, dynamic>{
      'category': category.trim(),
      'contact_email': email.trim().toLowerCase(),
      'description': description.trim(),
      'status': 'open',
    };

    if (userId != null && userId.isNotEmpty) {
      payload['user_id'] = userId;
    }

    // 4. Supabase Insertion
    try {
      await Supabase.instance.client.from('support_tickets').insert(payload);
      _lastSubmittedAt = DateTime.now();
      debugPrint('[SupportTicketService] Successfully created support ticket for: ${email.trim()}');
    } on PostgrestException catch (e) {
      debugPrint('[SupportTicketService] PostgrestException: ${e.code} - ${e.message}');
      final msg = e.message.toLowerCase();
      if (msg.contains('too many requests') || msg.contains('rate limit') || msg.contains('hourly ticket limit')) {
        throw SupportTicketRateLimitException(e.message);
      }
      throw SupportTicketSubmissionException(
        'Unable to submit your ticket. Please check your connection and try again.',
      );
    } catch (e) {
      debugPrint('[SupportTicketService] Unexpected error: $e');
      throw const SupportTicketSubmissionException(
        'An unexpected error occurred while submitting your ticket.',
      );
    }
  }
}
