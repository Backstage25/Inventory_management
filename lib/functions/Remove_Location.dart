import 'package:flutter/material.dart';
import 'package:inventory_management_system/screens/Dashboard.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';

class RemoveLoc extends StatelessWidget {
  const RemoveLoc({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleAppBar(
        title: 'REMOVE LOCATION',
        onBack: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        },
        onProfile: () {},
      ),
      body: Center(child: Text('yet to code')),
    );
  }
}
