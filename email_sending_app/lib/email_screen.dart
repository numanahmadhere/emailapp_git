// email_screen.dart
import 'package:flutter/material.dart';
import 'email_service.dart';
import 'google_sign_in_service.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'firestore_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class EmailScreen extends StatefulWidget {
  @override
  _EmailScreenState createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isSending = false;

  late EmailService _emailService;
  late GoogleSignInService _googleSignInService;
  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    // Delay access to context using addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _googleSignInService = Provider.of<GoogleSignInService>(context, listen: false);
      _firestoreService = Provider.of<FirestoreService>(context, listen: false);
     
      _emailService = EmailService(_googleSignInService, _firestoreService);
    });
  }

  Future<void> _sendEmail() async {
    final recipient = _recipientController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    if (recipient.isEmpty || subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (!_isValidEmail(recipient)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid recipient email address.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
  await _emailService.sendEmail(
    recipient: recipient,
    subject: subject,
    body: body,
    context: context,
  );
} catch (e) {
  // Handle the error appropriately
  logger.e('Error sending email: $e');
} finally {
  setState(() {
    _isSending = false;
  });
}


    setState(() {
      _isSending = false;
    });

    // Optionally, clear the fields after sending
    _recipientController.clear();
    _subjectController.clear();
    _bodyController.clear();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access GoogleSignInService via Provider to get real-time updates
    _googleSignInService = Provider.of<GoogleSignInService>(context, listen: false);

    final bool isGoogleConnected = _googleSignInService.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isGoogleConnected
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      'Connected as: ${_googleSignInService.currentUser!.email}',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _recipientController,
                      decoration: InputDecoration(
                        labelText: 'Recipient',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _bodyController,
                      decoration: InputDecoration(
                        labelText: 'Body',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSending ? null : _sendEmail,
                      child: _isSending
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text('Send Email'),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Please connect your Google account to send emails.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to Home to connect
                    },
                    child: const Text('Connect Google Account'),
                  ),
                ],
              ),
      ),
    );
  }
}
