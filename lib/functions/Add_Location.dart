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
  bool _added = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showConfirmSheet() {
    if (_controller.text.trim().isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              // EDIT Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              // CONFIRM Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() => _added = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
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
            SizedBox(height: 30),
            const Text(
              'LOCATION NAME',
              style: TextStyle(color: Colors.white, fontSize: 28, fontFamily: 'Roboto',fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontFamily : 'Inter'),
              decoration: InputDecoration(
                hintText: 'Enter location name',
                hintStyle: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize : 18),
                filled: true,
                fillColor: Color(0xFF2E2E2E),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Spacer(),
            if (!_added)

              Center (child :SizedBox(
                width: 150,
                height: 48,
                child: ElevatedButton(
                  onPressed: _showConfirmSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ADD',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ))
            else
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 80),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ADDED SUCCESSFULLY!',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}