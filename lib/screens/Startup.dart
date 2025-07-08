import 'package:flutter/material.dart';
import 'package:inventory_management_system/screens/Dashboard_Admin.dart';
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
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: screenSize.width * 0.6,
            height: screenSize.height * 0.3,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
