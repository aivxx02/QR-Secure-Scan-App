import 'package:flutter/cupertino.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';


/// email a notification for user submit report
Future<void> sendReportReviewMail(String recipientEmail, String url, String details) async {
  // Gmail SMTP server configuration
  const String username = ''; // insert your gmail
  const String password = ''; // Use an App Password, NOT your Gmail password

  final smtpServer = gmail(username, password);

  /// Create the email message
  final message = Message()
    ..from = Address(username, 'QR Secure Scan Support')
    ..recipients.add(recipientEmail)
    ..subject = 'Your Report Is Being Reviewed'
    ..text = 'Dear $recipientEmail,\n\nThank you for submitting a malicious URL report. '
        'Our team will review your report and take necessary actions.\n'
        'Here are the details of your report:\n\n'
        'Reported URL : $url\n'
        'Description : $details\n\n'
        'We will get back to you once the admin verifies or rejects your report.\n\n'
        'Best regards,\nQR Secure Scan Team';

  try {
    // Send the email
    await send(message, smtpServer);
    debugPrint('Email has been sent');
  } catch (e) {
    debugPrint('Failed to send email: $e');
  }
}


/// Email notification for user when admin verified the report
Future<void> reportVerificationMailVerified(
    String recipientEmail, String url, String details, String threatLevel, String adminReason) async {
  // Gmail SMTP server configuration
  const String username = ''; // insert your gmail
  const String password = ''; // Use an App Password, NOT your Gmail password

  final smtpServer = gmail(username, password);

  // Create the email message
  final message = Message()
    ..from = Address(username, 'QR Secure Scan Support')
    ..recipients.add(recipientEmail)
    ..subject = 'Your Report Has Been Verified'
    ..text = 'Dear $recipientEmail,\n\nThank you for submitting a malicious URL report. '
        'Our team has reviewed your report.\n\n'
        'Here are the details of your report:\n\n'
        'Malware Status: Malicious\n'
        'Reported URL: $url\n'
        'Threat Level: $threatLevel\n'
        'Admin Description: $adminReason\n\n'
        'Best regards,\nQR Secure Scan Team';

  try {
    await send(message, smtpServer);
    debugPrint('Verification email sent.');
  } catch (e) {
    debugPrint('Failed to send verification email: $e');
  }
}

/// Email notification for user when admin rejected the report
Future<void> reportVerificationMailRejected(
    String recipientEmail, adminReason, String url, String details) async {
  // Gmail SMTP server configuration
  const String username = ''; // insert your gmail
  const String password = ''; // Use an App Password, NOT your Gmail password

  final smtpServer = gmail(username, password);

  // Create the email message
  final message = Message()
    ..from = Address(username, 'QR Secure Scan Support')
    ..recipients.add(recipientEmail)
    ..subject = 'Your Report Has Been Rejected'
    ..text = 'Dear $recipientEmail,\n\nThank you for submitting a malicious URL report. '
        'Our team reviewed your report.\n\n'
        'Here are the details of your report:\n\n'
        'Malware Status: Safe\n'
        'Reported URL: $url\n'
        'Admin Description: $adminReason\n\n'

        'Best regards,\nQR Secure Scan Team';

  try {
    await send(message, smtpServer);
    debugPrint('Rejection email sent.');
  } catch (e) {
    debugPrint('Failed to send rejection email: $e');
  }
}
