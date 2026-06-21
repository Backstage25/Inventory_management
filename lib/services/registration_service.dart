import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:inventory_management_system/widgets/Auth.dart';

/// Validates that a user exists in `registered_users` and is still active.
class RegistrationService {
  static String? revocationMessage;

  static bool isRegistered(DocumentSnapshot doc) {
    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return false;

    return data['is_active'] ?? true;
  }

  static Future<bool> checkRegistration(String email) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('registered_users')
          .doc(email)
          .get();

      return isRegistered(doc);
    } catch (e) {
      debugPrint('Error checking registration: $e');
      return false;
    }
  }

  static Future<void> forceLogout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  static Future<void> removeRegisteredUser({
    required String email,
    required String removedBy,
    String? displayEmail,
  }) async {
    await FirebaseFirestore.instance
        .collection('registered_users')
        .doc(email)
        .delete();

    await FirebaseFirestore.instance.collection('history').add({
      'username': removedBy,
      'action': 'remove_user',
      'removed_user': displayEmail ?? email,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> handleRevokedAccess(GlobalKey<NavigatorState> navigatorKey) async {
    revocationMessage = 'Your access has been revoked. Please contact an administrator.';
    await forceLogout();

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Auth()),
      (_) => false,
    );
  }
}

/// Listens for changes to the current user's `registered_users` document
/// and signs them out immediately when access is revoked.
class RegistrationGuard extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const RegistrationGuard({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<RegistrationGuard> createState() => _RegistrationGuardState();
}

class _RegistrationGuardState extends State<RegistrationGuard> {
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  bool _isHandlingRevocation = false;
  bool _wasRegistered = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
    _wasRegistered = false;

    final email = user?.email;
    if (email == null) return;

    _userDocSubscription = FirebaseFirestore.instance
        .collection('registered_users')
        .doc(email)
        .snapshots()
        .listen(_onUserDocChanged);
  }

  Future<void> _onUserDocChanged(DocumentSnapshot snapshot) async {
    if (RegistrationService.isRegistered(snapshot)) {
      _wasRegistered = true;
      return;
    }

    // Deactivated but document still exists.
    if (snapshot.exists) {
      await _handleRevokedAccess();
      return;
    }

    // Document was deleted after the user had already been registered.
    if (_wasRegistered) {
      await _handleRevokedAccess();
    }
  }

  Future<void> _handleRevokedAccess() async {
    if (_isHandlingRevocation) return;
    _isHandlingRevocation = true;

    await RegistrationService.handleRevokedAccess(widget.navigatorKey);

    if (mounted) {
      _isHandlingRevocation = false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
