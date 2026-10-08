import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns Supabase auth errors into calm, specific sentences a parent can act
/// on. Anything unrecognised falls back to Supabase's own message.
String authErrorMessage(Object error) {
  if (error is! AuthException) {
    return 'We couldn’t reach Curio. Check your connection and try again.';
  }
  final wait = retryAfterSeconds(error);
  if (wait != null) {
    return 'For your security, please wait $wait seconds before asking for another email.';
  }
  switch (error.code) {
    case 'invalid_credentials':
      return 'That email and password don’t match. Try again, or reset your password.';
    case 'user_already_exists':
    case 'email_exists':
      return 'There’s already a Curio account for this email. Try signing in instead.';
    case 'weak_password':
      return 'Please choose a stronger password — at least 8 characters, with letters and numbers.';
    case 'otp_expired':
      return 'That code isn’t right or has expired. Check the newest email, or send a fresh code.';
    case 'otp_disabled':
    case 'signup_disabled':
    case 'user_not_found':
      return 'We couldn’t find a Curio account for that email. Check the spelling, or create an account.';
    case 'email_address_invalid':
      return 'That email address doesn’t look quite right.';
    case 'email_address_not_authorized':
      return kDebugMode
          ? 'Supabase’s built-in mailer only sends to your project’s team members. Set up custom SMTP (SUPABASE_SETUP.md, step 5) to email anyone.'
          : 'We couldn’t send an email to this address just now. Please try again later.';
    case 'over_email_send_rate_limit':
      return 'We’ve sent a lot of emails in the last little while. Please wait a few minutes and try again.';
    case 'over_request_rate_limit':
      return 'That’s a lot of attempts in a row. Take a short break, then try again.';
    case 'same_password':
      return 'That’s your current password. Choose a new one.';
    case 'user_banned':
      return 'This account has been paused. Please contact support.';
  }
  if (error.statusCode == '429') {
    return 'That’s a lot of attempts in a row. Take a short break, then try again.';
  }
  return error.message;
}

bool isEmailNotConfirmed(Object error) =>
    error is AuthException &&
    (error.code == 'email_not_confirmed' ||
        error.message.toLowerCase().contains('email not confirmed'));

/// Supabase allows one email per address per minute and says so as
/// "…you can only request this after 42 seconds."
int? retryAfterSeconds(Object error) {
  if (error is! AuthException) return null;
  final match = RegExp(r'after (\d+) seconds?').firstMatch(error.message);
  return match == null ? null : int.tryParse(match.group(1)!);
}
