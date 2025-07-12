import 'package:flutter/material.dart';
import 'package:inventory_management_system/screens/Dashboard_Admin.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfirmRemoveScreen extends StatelessWidget {
  final String locationId;
  final String locationName;

  const ConfirmRemoveScreen({
    super.key,
    required this.locationId,
    required this.locationName,
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
      appBar: SimpleAppBar(
        title: 'REMOVE LOCATION',
        onBack: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardAdmin()),
          );
        },
        onProfile: () {},
      ),
      backgroundColor: Color(0xFF1E1E1E),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: scaleW(32),
          vertical: scaleH(80),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CHOOSE LOCATION",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: scaleW(25),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: scaleH(12)),
            Container(
              width: double.infinity,
              height: scaleH(53),
              padding: EdgeInsets.symmetric(horizontal: scaleW(12)),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                locationName,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: scaleW(24),
                  color: Colors.white,
                ),
              ),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: screenWidth * 0.4,
                  height: scaleH(48),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      'EDIT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: scaleW(16),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: screenWidth * 0.4,
                  height: scaleH(48),
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final firestore = FirebaseFirestore.instance;
                        final docRef = firestore.collection('locations').doc(locationId);
                        final docSnapshot = await docRef.get();

                        if (!docSnapshot.exists) {
                          throw Exception('Location not found');
                        }

                        final itemsSnapshot = await docRef.collection('inventory').get();

                        final allZero = itemsSnapshot.docs.every((doc) {
                          final quantity = doc['Quantity'];
                          return quantity == 0;
                        });

                        if (!allZero) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Cannot delete: Some items have quantity > 0.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        for (final item in itemsSnapshot.docs) {
                          await item.reference.delete();
                        }

                        await docRef.delete();

                        Navigator.pop(context, true);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to remove location: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      'CONFIRM',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: scaleW(19),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // SizedBox(height: scaleH(40)),
          ],
        ),
      ),
    );
  }
}
