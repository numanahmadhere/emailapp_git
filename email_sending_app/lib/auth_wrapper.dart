import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while checking the authentication state
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // User is logged in, show the Home Screen
          return HomeScreen();
        } else {
          // User is not logged in, show the Login Screen
          return LoginScreen();
        }
      },
    );
  }
}
