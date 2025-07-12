import 'package:flutter/material.dart';
import 'package:inventory_management_system/screens/Dashboard.dart';
import 'package:inventory_management_system/screens/Dashboard_Admin.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({Key? key}) : super(key: key);

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();

  // Set admin PIN here (can be later fetched from a secure source)
  final String _adminPin = "000000";

  // Function to check the password and navigate
  void _validatePassword() {
    if (_passwordController.text == _adminPin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DashboardAdmin()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password')),
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
        title: 'APPBAR',
        onBack: () {
          Navigator.pop(context);
        },
        onProfile: () {},
      ),
      // Main content
      body: Column(
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
              style: const TextStyle(color: Colors.white, fontFamily : 'Inter'),
              decoration: InputDecoration(
                counterText: "",
                hintText: 'Enter Password',
                hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Roboto', fontSize : screenWidth * 0.05),
                filled: true,
                fillColor: Color(0xFF2E2E2E),
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
                          fontWeight: FontWeight.bold
                      ),
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
                    onPressed: _validatePassword,
                    child: Text(
                      'CONFIRM',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20 * fontScale,
                          fontWeight: FontWeight.bold
                      ),
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
}