import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_management_system/functions/Remove_Inventory.dart';
import 'package:inventory_management_system/widgets/Dashboard_Button.dart';
import 'package:inventory_management_system/functions/Add_Items.dart';
import 'package:inventory_management_system/functions/Remove_Location.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    double buttonWidth = screenWidth * 0.8;
    if (buttonWidth > 400) buttonWidth = 400;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: SimpleAppBar(
        title: 'ADMIN OPTIONS',
        onBack: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        onProfile: () {},
      ),
      body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DashboardButton(
                    iconPath: 'assets/icons/add_items.svg',
                    label: "ADD ITEMS",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddItemsPage()),
                      );
                    }
                ),
                DashboardButton(
                    iconPath: 'assets/icons/remove_location.svg',
                    label: "REMOVE LOCATION",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RemoveLoc()),
                      );
                    }
                ),
                DashboardButton(
                    iconPath: 'assets/icons/remove_items.svg',
                    label: "REMOVE ITEMS",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RemoveInventoryPage()),
                      );
                    }
                ),
                DashboardButton(
                  iconPath: 'assets/icons/invite.svg', // Use a suitable icon
                  label: "EXPORT",
                  onPressed: () {
                    _exportInventoryToCSV(context);
                  },
                ),
                DashboardButton(
                    iconPath: 'assets/icons/invite.svg', // You'll need to add this icon
                    label: "INVITE USER",
                    onPressed: () {
                      _showInviteDialog(context);
                    }
                )
              ],
            ),
          )
      ),
    );
  }

  Future<void> _exportInventoryToCSV(BuildContext context) async {
    try {
      // Request storage permission
      // if (Platform.isAndroid) {
      // if (!(await Permission.storage.request().isGranted)) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Permission required to save in Downloads folder.'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }}

      // Fetch all locations
      final locationsSnapshot =
      await FirebaseFirestore.instance.collection('locations').get();

      List<List<dynamic>> csvData = [
        ['Location', 'Item Name', 'Quantity']
      ];
      Map<String, int> allItemsTotal = {}; // itemName -> totalQty
      for (final locDoc in locationsSnapshot.docs){
        final invSnapshot = await FirebaseFirestore.instance
            .collection('locations')
            .doc(locDoc.id)
            .collection('inventory')
            .get();

        bool firstItem = true;
        for (final itemDoc in invSnapshot.docs) {
          final data = itemDoc.data();
          final itemName = data['Item Name'];
          // Firestore can return num, so force int
          int qty = (data['Quantity'] ?? 0) is int
              ? (data['Quantity'] ?? 0)
              : ((data['Quantity'] ?? 0) as num).toInt();
          if (itemName != null) {
            if (firstItem) {
              csvData.add([locDoc.id, itemName, qty.toString(), '']);
              firstItem = false;
            } else {
              csvData.add(['', itemName, qty.toString(), '']);
            }
            allItemsTotal[itemName] = (allItemsTotal[itemName] ?? 0) + qty;
          }
        }
      }

      csvData.add(['ALL', '', '']);
      allItemsTotal.forEach((item, qty) {
        csvData.add(['', item, qty.toString()]);
      });


      // Convert to CSV
      String csv = const ListToCsvConverter().convert(csvData);

      // Get the Downloads directory
      final downloadsPath = '/storage/emulated/0/Download'; // Public Downloads on most Android devices
      if (downloadsPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Downloads directory not available'),
            backgroundColor: Colors.red));
        return;
      }
      final path = "${downloadsPath}/inventory_export.csv";
      print('Export path: $path');
      final file = File(path);
      await file.writeAsString(csv);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inventory exported to Downloads:\n$path'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const InviteUserDialog();
      },
    );
  }
}

class InviteUserDialog extends StatefulWidget {
  const InviteUserDialog({Key? key}) : super(key: key);

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _generatedCode;
  bool _isSuccess = false;

  Future<void> _sendEmail(String inviteCode, String recipientEmail) async {
    String username = 'backstage25.app@gmail.com'; // Your Gmail address
    String password = 'qgnbpyshegzaznmi'; // Your Gmail password or App Password

    final smtpServer = gmail(username, password);

    // Create the email message
    final message = Message()
      ..from = Address(username)
      ..recipients.add(recipientEmail)
      ..subject = 'Your Invite Code'
      ..text = 'Your invite code is: $inviteCode';

    try {
      await send(message, smtpServer);
      print('Email sent successfully!');
    } catch (e) {
      print('Failed to send email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          Icon(
            _isSuccess ? Icons.check_circle : Icons.person_add,
            size: 48,
            color: _isSuccess ? Colors.green : Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            _isSuccess ? 'Invitation Created!' : 'Invite New User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: _isSuccess ? _buildSuccessContent() : _buildInviteContent(),
      actions: _isSuccess ? _buildSuccessActions() : _buildInviteActions(),
    );
  }

  Widget _buildInviteContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter the email address of the person you want to invite:',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Enter email address',
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
            prefixIcon: const Icon(
              Icons.email,
              color: Colors.grey,
            ),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Invitation code generated for:',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _emailController.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text(
                'Invite Code:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _generatedCode ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedCode ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invite code copied to clipboard'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.copy,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Share this code with the invited user. It expires in 7 days.',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget> _buildInviteActions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : () {
          Navigator.of(context).pop();
        },
        child: const Text(
          'Cancel',
          style: TextStyle(color: Colors.grey),
        ),
      ),
      ElevatedButton(
        onPressed: _isLoading ? null : _generateInvite,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Generate Invite'),
      ),
    ];
  }

  List<Widget> _buildSuccessActions() {
    return [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text(
          'Done',
          style: TextStyle(color: Colors.blue),
        ),
      ),
    ];
  }

  Future<void> _generateInvite() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter an email address', Colors.red);
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showSnackBar('Please enter a valid email address', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String email = _emailController.text.trim().toLowerCase();

      // Get current user info first
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSnackBar('Authentication error', Colors.red);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Current user: ${currentUser.email}');
      print('Inviting email: $email');

      // Check if user is already registered
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('registered_users')
            .doc(email)
            .get();

        print('User doc exists: ${userDoc.exists}');

        if (userDoc.exists) {
          _showSnackBar('User is already registered', Colors.orange);
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Error checking registered users: $e');
        // Continue with invitation creation even if this check fails
      }

      // Check if there's already a pending invitation
      try {
        QuerySnapshot pendingInvites = await FirebaseFirestore.instance
            .collection('pending_invitations')
            .where('email', isEqualTo: email)
            .where('used', isEqualTo: false)
            .where('expires_at', isGreaterThan: Timestamp.now())
            .get();

        print('Pending invites count: ${pendingInvites.docs.length}');

        if (pendingInvites.docs.isNotEmpty) {
          _showSnackBar('Active invitation already exists for this email', Colors.orange);
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Error checking pending invitations: $e');
        // Continue with invitation creation even if this check fails
      }

      // Generate unique invite code
      String inviteCode = _generateInviteCode();


      // Create invitation document
      Map<String, dynamic> inviteData = {
        'email': email,
        'invite_code': inviteCode,
        'invited_by': currentUser.email ?? 'unknown',
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'used': false,
        'used_at': null,
      };


      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('pending_invitations')
          .add(inviteData);

      // After creating the invitation document
      await _sendEmail(inviteCode, email);
      setState(() {
        _generatedCode = inviteCode;
        _isSuccess = true;
        _isLoading = false;
      });

      _showSnackBar('Invitation created successfully!', Colors.green);

    } catch (e) {
      print('Error generating invite: $e');
      print('Error type: ${e.runtimeType}');

      String errorMessage = 'Error generating invitation. Please try again.';

      // Provide more specific error messages
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check your admin privileges.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('unauthenticated')) {
        errorMessage = 'Authentication error. Please sign in again.';
      }

      _showSnackBar(errorMessage, Colors.red);
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateInviteCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
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
    _emailController.dispose();
    super.dispose();
  }
}