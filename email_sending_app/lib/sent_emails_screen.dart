// screens/sent_emails_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firestore_service.dart';
import 'sent_email.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class SentEmailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sent Emails'),
      ),
      body: StreamBuilder<List<SentEmail>>(
        stream: _firestoreService.getSentEmails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No sent emails found.'));
          }

          final sentEmails = snapshot.data!;

          return ListView.builder(
            itemCount: sentEmails.length,
            itemBuilder: (context, index) {
              final email = sentEmails[index];
              return ListTile(
                leading: Icon(Icons.email),
                title: Text(email.subject),
                subtitle: Text('To: ${email.recipient}\nSent: ${email.timestamp.toDate()}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    // Confirm deletion
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Email'),
                        content: Text('Are you sure you want to delete this email from the log?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await _firestoreService.deleteSentEmail(email.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Email deleted successfully.')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete email: $e')),
                        );
                      }
                    }
                  },
                ),
                onTap: () {
                  // Optional: Show email details
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(email.subject),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('To: ${email.recipient}'),
                            SizedBox(height: 10),
                            Text(email.body),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
