import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';
import '../screens/Dashboard.dart';

class AddLoc extends StatefulWidget {
  const AddLoc({super.key});
  @override
  State<AddLoc> createState() => _AddLocState();
}

class _AddLocState extends State<AddLoc> {
  final _controller = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSuccessDialog(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Success',
          style: TextStyle(
            color: Colors.green,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.055,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w500,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.045,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: Text('Error', style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.05)),
        content: Text(message, style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045)),
          )
        ],
      ),
    );
  }

  Future<void> _showConfirmDialog() async {
    if (_controller.text.trim().isEmpty) {
      _showErrorDialog("Please enter a location name.");
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final locationName = _controller.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Confirm Addition',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.055,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to add this location?',
              style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.045),
            ),
            SizedBox(height: screenWidth * 0.025),
            Text('Location Name: $locationName', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Add', style: TextStyle(color: Colors.green, fontSize: screenWidth * 0.045)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      await _addLocation(locationName);
    }
  }

  Future<void> _addLocation(String locationName) async {
    setState(() {
      _isProcessing = true;
    });

    final locationDoc = FirebaseFirestore.instance.collection('locations').doc(locationName);

    try {
      // Check if location already exists
      final docSnapshot = await locationDoc.get();
      if (docSnapshot.exists) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog('A location with this name already exists.');
        return;
      }

      // Create location document with a field `name`
      await locationDoc.set({'name': locationName});

      // Create initial inventory document `0` with Quantity 0
      await locationDoc.collection('inventory').doc('0').set({'Quantity': 0});

      setState(() {
        _isProcessing = false;
        _controller.clear(); // Clear the text field immediately after adding
      });
      _showSuccessDialog("Added Successfully");
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Error adding location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: SimpleAppBar(
        title: 'ADD LOCATION',
        onBack: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        },
        onProfile: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenWidth * 0.1),
            Text(
              'LOCATION NAME',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.075,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenWidth * 0.05),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              decoration: InputDecoration(
                hintText: 'Enter location name',
                hintStyle: TextStyle(
                    color: Colors.white54,
                    fontFamily: 'Inter',
                    fontSize: screenWidth * 0.05),
                filled: true,
                fillColor: const Color(0xFF2E2E2E),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: SizedBox(
                width: screenWidth * 0.35,
                height: screenWidth * 0.125,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _showConfirmDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? SizedBox(
                    width: screenWidth * 0.045,
                    height: screenWidth * 0.045,
                    child: const CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'ADD',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.05),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
