// home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'new_campaign_screen.dart';
import 'email_screen.dart';
import 'google_sign_in_service.dart';
import 'sent_emails_screen.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:logger/logger.dart';

final logger = Logger();

class HomeScreen extends StatefulWidget {
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService firestoreService = FirestoreService();
  late GoogleSignInService _googleSignInService;

  int _currentIndex = 0; // For Bottom Navigation

  late List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    // Access the GoogleSignInService from Provider
    // WidgetsBinding ensures that context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _googleSignInService = Provider.of<GoogleSignInService>(context);
      _googleSignInService.initialize().then((_) {
        setState(() {}); // Refresh UI after initialization
        logger.e('GoogleSignInService initialized in HomeScreen.');
      });
       _tabs = [

        // Tab 0: Home Content

        _buildHomeContent(),

        // Tab 1: Sent Emails

        SentEmailsScreen(),

      ];
    });
  }

  // Build Home Content for Tab 0

  Widget _buildHomeContent() {

    return Padding(

      padding: const EdgeInsets.all(16.0),

      child: Column(

        children: [

          // User Information and Google Account Connection

          Text(

            'Welcome, ${_auth.currentUser?.email ?? 'User'}!',

            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),

          ),

          const SizedBox(height: 20),

          _googleSignInService.currentUser != null

              ? Column(

                  children: [

                    Text(

                      'Connected as: ${_googleSignInService.currentUser!.email}',

                      style: TextStyle(fontSize: 16),

                    ),

                    const SizedBox(height: 10),

                    ElevatedButton(

                      onPressed: _disconnectGoogleAccount,

                      child: const Text('Disconnect Google Account'),

                    ),

                  ],

                )

              : ElevatedButton(

                  onPressed: _connectGoogleAccount,

                  child: const Text('Connect Google Account'),

                ),

          const SizedBox(height: 20),

          // Navigation Buttons

          ElevatedButton(

            onPressed: () {

              Navigator.push(

                context,

                MaterialPageRoute(builder: (context) => EmailScreen()),

              );

            },

            child: const Text('Send an Email'),

          ),

          const SizedBox(height: 20),

          ElevatedButton(

            onPressed: () {

              Navigator.push(

                context,

                MaterialPageRoute(builder: (context) => NewCampaignScreen()),

              );

            },

            child: const Text('Add New Campaign'),

          ),

          const SizedBox(height: 20),

          // Email Campaigns List

          Expanded(

            child: StreamBuilder<List<Map<String, dynamic>>>(

              stream: firestoreService.getEmailCampaigns(),

              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {

                  return Center(child: CircularProgressIndicator());

                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {

                  return const Center(child: Text("No campaigns found."));

                }



                List<Map<String, dynamic>> campaigns = snapshot.data!;

                return ListView.builder(

                  itemCount: campaigns.length,

                  itemBuilder: (context, index) {

                    final campaign = campaigns[index];

                    return ListTile(

                      title: Text(campaign['subject']),

                      subtitle: Text(campaign['recipient']),

                      trailing: IconButton(

                        icon: const Icon(Icons.delete),

                        onPressed: () {

                          firestoreService.deleteEmailCampaign(campaign['id']);

                          ScaffoldMessenger.of(context).showSnackBar(

                            SnackBar(content: Text('Campaign deleted.')),

                          );

                        },

                      ),

                    );

                  },

                );

              },

            ),

          ),

        ],

      ),

    );

  }




  Future<void> _signOut() async {
    await _auth.signOut();
    await _googleSignInService.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Redirect to login after signing out
    logger.e('User signed out from Firebase and Google.');
  }

  Future<void> _connectGoogleAccount() async {
    bool success = await _googleSignInService.signIn();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google account connected successfully!')),
      );
      setState(() {}); // Refresh UI
      logger.e('Google account connected.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect Google account.')),
      );
      logger.e('Failed to connect Google account.');
    }
  }

  Future<void> _disconnectGoogleAccount() async {
    await _googleSignInService.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google account disconnected.')),
    );
    setState(() {}); // Refresh UI
    logger.e('Google account disconnected.');
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    // Access GoogleSignInService via Provider
    // This allows the UI to react to changes
    _googleSignInService = Provider.of<GoogleSignInService>(context);

    final bool isGoogleConnected = _googleSignInService.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: 
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Information and Google Account Connection
            Text(
              'Welcome, ${user?.email ?? 'User'}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            isGoogleConnected
                ? Column(
                    children: [
                      Text(
                        'Connected as: ${_googleSignInService.currentUser!.email}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _disconnectGoogleAccount,
                        child: const Text('Disconnect Google Account'),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _connectGoogleAccount,
                    child: const Text('Connect Google Account'),
                  ),
            const SizedBox(height: 20),
            // Navigation Buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EmailScreen()),
                );
              },
              child: const Text('Send an Email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewCampaignScreen()),
                );
              },
              child: const Text('Add New Campaign'),
            ),
            const SizedBox(height: 20),
            // Email Campaigns List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: firestoreService.getEmailCampaigns(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No campaigns found."));
                  }

                  List<Map<String, dynamic>> campaigns = snapshot.data!;
                  return ListView.builder(
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      return ListTile(
                        title: Text(campaign['subject']),
                        subtitle: Text(campaign['recipient']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            firestoreService.deleteEmailCampaign(campaign['id']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Campaign deleted.')),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewCampaignScreen()),
          );
        },

        
        child: Icon(Icons.add),
        tooltip: 'Add New Campaign',
      ),
    );
  }
}
