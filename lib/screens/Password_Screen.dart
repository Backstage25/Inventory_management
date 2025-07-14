import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory_management_system/screens/Dashboard_Admin.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({Key? key}) : super(key: key);

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _adminPin;

  @override
  void initState() {
    super.initState();
    _fetchAdminPin();
  }

  // Fetch admin PIN from Firebase
  Future<void> _fetchAdminPin() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch from Firestore (adjust collection/document path as needed)
      DocumentSnapshot doc = await _firestore
          .collection('settings')
          .doc('admin_config')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        _adminPin = data['admin_pin']?.toString();
      }

      // Alternative: You can also store it in Firebase Remote Config
      // or Firebase Realtime Database based on your preference

    } catch (e) {
      // Fallback to a default PIN or show error
      _adminPin = "000000"; // Fallback PIN

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading configuration. Using default settings.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Function to check the password and navigate
  Future<void> _validatePassword() async {
    if (_adminPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration not loaded. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text == _adminPin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardAdmin()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width and height for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double fontScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background color
      appBar: SimpleAppBar(
        title: '',
        onBack: () {
          Navigator.pop(context);
        },
        onProfile: () {},
      ),
      // Main content
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Column(
        children: [
          SizedBox(height: screenHeight * 0.35), // Spacer

          // Password TextField
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            child: TextField(
              controller: _passwordController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              decoration: InputDecoration(
                counterText: "",
                hintText: 'Enter Password',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Roboto',
                  fontSize: screenWidth * 0.05,
                ),
                filled: true,
                fillColor: const Color(0xFF2E2E2E),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.05), // Spacer

          // Buttons Row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 20 * fontScale,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(width: 16), // Space between buttons

                // Confirm Button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: _adminPin != null ? _validatePassword : null,
                    child: Text(
                      'CONFIRM',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20 * fontScale,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}