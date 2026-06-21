import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:inventory_management_system/screens/Dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: screenSize.width * 0.5,
                  height: screenSize.height * 0.25,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: screenSize.height * 0.05),
                ElevatedButton.icon(
                  onPressed: () async {
                    bool islogged = await login();

                    if (islogged) {
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        // Check if user needs invite code
                        bool needsInviteCode = await _needsInviteCode(user.email!);

                        if (needsInviteCode) {
                          // Show invite code dialog
                          _showInviteCodeDialog(context, user.email!);
                        } else {
                          // User is already registered, go to dashboard
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Dashboard()),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: Image.asset(
                    'assets/images/google.png',
                    height: screenSize.height * 0.03, // responsive height
                  ),
                  label: Text(
                    'Sign in with Google',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenSize.width * 0.045, // responsive font size
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> login() async {
    try {
      final user = await GoogleSignIn().signIn();

      if (user == null) {
        return false; // User cancelled sign in
      }

      GoogleSignInAuthentication userAuth = await user.authentication;

      var credential = GoogleAuthProvider.credential(
        idToken: userAuth.idToken,
        accessToken: userAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Check if user needs to enter invite code
  Future<bool> _needsInviteCode(String email) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('registered_users')
          .doc(email)
          .get();

      return !userDoc.exists;
    } catch (e) {
      print('Error checking invite code requirement: $e');
      return true; // Default to requiring code if error
    }
  }

  // Show invite code dialog
  void _showInviteCodeDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return InviteCodeDialog(
          email: email,
          onSuccess: () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()),
            );
          },
          onCancel: () {
            Navigator.of(context).pop(); // Close dialog
            // Sign out user since they cancelled
            FirebaseAuth.instance.signOut();
            GoogleSignIn().signOut();
          },
        );
      },
    );
  }
}

// Invite Code Dialog Widget
class InviteCodeDialog extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const InviteCodeDialog({
    Key? key,
    required this.email,
    required this.onSuccess,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<InviteCodeDialog> createState() => _InviteCodeDialogState();
}

class _InviteCodeDialogState extends State<InviteCodeDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AlertDialog(
      backgroundColor: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          const Icon(
            Icons.mail_outline,
            size: 48,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Invite Code Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Please enter the invite code sent to:',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'Enter 6-digit code',
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.text,
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : widget.onCancel,
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Verify'),
        ),
      ],
    );
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().isEmpty) {
      _showSnackBar('Please enter the invite code', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Find matching invitation
      QuerySnapshot inviteQuery = await FirebaseFirestore.instance
          .collection('pending_invitations')
          .where('email', isEqualTo: widget.email)
          .where('invite_code', isEqualTo: _codeController.text.trim().toUpperCase())
          .where('used', isEqualTo: false)
          .where('expires_at', isGreaterThan: Timestamp.now())
          .get();

      if (inviteQuery.docs.isEmpty) {
        _showSnackBar('Invalid or expired invite code', Colors.red);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      DocumentSnapshot inviteDoc = inviteQuery.docs.first;
      Map<String, dynamic> inviteData = inviteDoc.data() as Map<String, dynamic>;

      // Mark invitation as used
      await inviteDoc.reference.update({
        'used': true,
        'used_at': FieldValue.serverTimestamp(),
      });

      // Register user
      await FirebaseFirestore.instance
          .collection('registered_users')
          .doc(widget.email)
          .set({
        'email': widget.email,
        'registered_at': FieldValue.serverTimestamp(),
        'invited_by': inviteData['invited_by'],
        'invite_code_used': _codeController.text.trim().toUpperCase(),
        'is_active': true,
      });

      _showSnackBar('Welcome! Registration successful', Colors.green);

      // Small delay to show success message
      await Future.delayed(const Duration(seconds: 1));

      widget.onSuccess();

    } catch (e) {
      print('Error verifying invite code: $e');
      _showSnackBar('Error verifying code. Please try again.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}