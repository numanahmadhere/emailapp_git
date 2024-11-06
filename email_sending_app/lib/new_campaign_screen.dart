import 'package:flutter/material.dart';
import 'firestore_service.dart';

class NewCampaignScreen extends StatefulWidget {
  @override
  _NewCampaignScreenState createState() => _NewCampaignScreenState();
}

class _NewCampaignScreenState extends State<NewCampaignScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();

  void _addCampaign() {
    firestoreService.addEmailCampaign(
      recipientController.text,
      subjectController.text,
      bodyController.text,
    );
    Navigator.pop(context); // Go back to the previous screen after adding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Campaign')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: recipientController,
              decoration: InputDecoration(labelText: 'Recipient'),
            ),
            TextField(
              controller: subjectController,
              decoration: InputDecoration(labelText: 'Subject'),
            ),
            TextField(
              controller: bodyController,
              decoration: InputDecoration(labelText: 'Body'),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addCampaign,
              child: Text('Add Campaign'),
            ),
          ],
        ),
      ),
    );
  }
}
