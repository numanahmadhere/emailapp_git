import 'package:cloud_firestore/cloud_firestore.dart';
import 'sent_email.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new email campaign
  Future<void> addEmailCampaign(String recipient, String subject, String body) async {
    try {
      await _db.collection('emails').add({
        'recipient': recipient,
        'subject': subject,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(), // Automatically set the timestamp
      });
    } catch (e) {
      logger.e("Error adding email campaign: $e");
    }
  }

  // Retrieve all email campaigns
  Stream<List<Map<String, dynamic>>> getEmailCampaigns() {
    return _db.collection('emails').orderBy('timestamp', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => {
        'id': doc.id,
        'recipient': doc['recipient'],
        'subject': doc['subject'],
        'body': doc['body'],
        'timestamp': doc['timestamp'],
      }).toList(),
    );
  }

  // Update an existing email campaign
  Future<void> updateEmailCampaign(String id, String recipient, String subject, String body) async {
    try {
      await _db.collection('emails').doc(id).update({
        'recipient': recipient,
        'subject': subject,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e("Error updating email campaign: $e");
    }
  }

  // Delete an email campaign
  Future<void> deleteEmailCampaign(String id) async {
    try {
      await _db.collection('emails').doc(id).delete();
    } catch (e) {
      logger.e("Error deleting email campaign: $e");
    }
  }

  
// Collection reference for sent emails
  CollectionReference get _sentEmailsRef => _db.collection('sent_emails');

  // Add a sent email to Firestore
  Future<void> logSentEmail(SentEmail email) async {
    try {
      await _sentEmailsRef.add(email.toMap());
      logger.e('Email logged successfully.');
    } catch (e) {
      logger.e('Error logging email: $e');
      rethrow;
    }
  }

  // Stream of sent emails
  Stream<List<SentEmail>> getSentEmails() {
    return _sentEmailsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SentEmail.fromDocument(doc))
            .toList());
  }

  // Optional: Delete a sent email
  Future<void> deleteSentEmail(String id) async {
    try {
      await _sentEmailsRef.doc(id).delete();
      logger.e('Email deleted successfully.');
    } catch (e) {
      logger.e('Error deleting email: $e');
      rethrow;
    }
  }


}
