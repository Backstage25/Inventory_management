import 'package:flutter/material.dart';
import 'package:inventory_management_system/screens/Dashboard.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';

class ConfirmItemsPage extends StatelessWidget {
  final String itemName;
  final String itemType;
  final String location;

  const ConfirmItemsPage({
    super.key,
    required this.itemName,
    required this.itemType,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const designWidth = 440.0;
    const designHeight = 956.0;

    double scaleW(double px) => px / designWidth * screenWidth;
    double scaleH(double px) => px / designHeight * screenHeight;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: SimpleAppBar(
        title: 'ADD ITEMS',
        onBack: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        },
        onProfile: () {},
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: scaleW(32),
          right: scaleW(32),
          top: scaleH(100),
          bottom: scaleH(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('ITEM NAME'),
            _buildDisplayBox(itemName),

            SizedBox(height: scaleH(40)),

            _buildLabel('ITEM TYPE'),
            _buildDisplayBox(itemType),

            SizedBox(height: scaleH(40)),

            _buildLabel('LOCATION'),
            _buildDisplayBox(location),

            SizedBox(height: scaleH(60)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildButton(
                  label: 'Edit',
                  onPressed: () {
                    Navigator.pop(context); // Go back to edit
                  },
                  filled: false,
                ),
                _buildButton(
                  label: 'Confirm',
                  onPressed: () {
                    _showSuccessDialog(context);
                  },
                  filled: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildDisplayBox(String value) {
    return Container(
      width: double.infinity,
      height: 53,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required bool filled,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: filled ? Colors.black : Colors.white,
        backgroundColor: filled ? Colors.white : Colors.transparent,
        side: filled ? null : const BorderSide(color: Colors.white),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(label),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Text(
            'ADDED SUCCESSFULLY!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.1,
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
