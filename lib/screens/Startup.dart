import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventory_management_system/widgets/Auth.dart';
import 'package:inventory_management_system/screens/Dashboard.dart';

class StartUp extends StatefulWidget {
  const StartUp({super.key});

  @override
  State<StartUp> createState() => _StartUpState();
}

class _StartUpState extends State<StartUp> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    // Add a delay to show the splash screen
    Future.delayed(const Duration(seconds:1), () {
      // Check if user is already signed in
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is logged in, navigate to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      } else {
        // User is not logged in, navigate to Auth
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Auth()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenSize.width * 0.6),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: screenSize.width * 0.6,
                height: screenSize.height * 0.3,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: screenSize.height * 0.05),
            Center(
               child: Text(
                 "Developed With ❤️",
                 style: TextStyle(
                   fontFamily: 'Inter',
                   fontSize: screenSize.height * 0.03,
                   color: Colors.white
                 ),
               ),
            ),
            Center(
              child: Text(
                "Backstage 25'-26'",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: screenSize.height * 0.03,
                  color: Colors.white
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}