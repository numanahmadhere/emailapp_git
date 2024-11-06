// lib/services/email_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'google_sign_in_service.dart'; // Import the GoogleSignInService
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'sent_email.dart'; // Import the SentEmail model (adjust the path as needed)
import 'firestore_service.dart'; // Import the FirestoreService
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class EmailService {
  final GoogleSignInService _googleSignInService;
  final FirestoreService _firestoreService;

  EmailService(this._googleSignInService, this._firestoreService);

  // Public getter
  GoogleSignInService get googleSignInService => _googleSignInService;

  Future<void> sendEmail({
    required String recipient,
    required String subject,
    required String body,
    required BuildContext context,
  }) async {
    // Get Gmail API client
    final gmailApi = await _googleSignInService.getGmailApiClient();
    if (gmailApi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please connect your Google account first.')),
      );
      return;
    }

    // Create the email
    final message = gmail.Message();
    final emailContent = '''
To: $recipient
Subject: $subject
Content-Type: text/plain; charset="UTF-8"

$body
''';

    // Encode the email in base64url without padding
    message.raw = base64UrlEncode(utf8.encode(emailContent)).replaceAll('=', '');

    try {
      // Attempt to send the email
      await gmailApi.users.messages.send(message, 'me');
      logger.e('Email sent successfully to $recipient');

      // Notify the user of success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email sent successfully!')),
      );

      // Log the sent email in Firestore
      final sentEmail = SentEmail(
        id: '', // Firestore will auto-generate the ID
        recipient: recipient,
        subject: subject,
        body: body,
        timestamp: Timestamp.now(),
      );
      await _firestoreService.logSentEmail(sentEmail);
      logger.e('Email logged successfully in Firestore.');
    } catch (e, stacktrace) {
      // Handle errors during email sending
      logger.e('Error sending email: $e');
      logger.e('Stacktrace: $stacktrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send email: $e')),
      );
    }
  }
}


