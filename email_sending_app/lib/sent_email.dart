// models/sent_email.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class SentEmail {
  final String id;
  final String recipient;
  final String subject;
  final String body;
  final Timestamp timestamp;

  SentEmail({
    required this.id,
    required this.recipient,
    required this.subject,
    required this.body,
    required this.timestamp,
  });

  // Factory constructor to create a SentEmail from Firestore document
  factory SentEmail.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SentEmail(
      id: doc.id,
      recipient: data['recipient'] ?? '',
      subject: data['subject'] ?? '',
      body: data['body'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  // Convert SentEmail to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'recipient': recipient,
      'subject': subject,
      'body': body,
      'timestamp': timestamp,
    };
  }
}
