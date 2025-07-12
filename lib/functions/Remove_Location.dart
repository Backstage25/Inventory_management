import 'package:flutter/material.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RemoveLoc extends StatefulWidget {
  @override
  _RemoveLocState createState() => _RemoveLocState();
}

class _RemoveLocState extends State<RemoveLoc> {
  String? _selectedLocationId;
  List<Map<String, String>> _locations = [];
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    final snapshot = await FirebaseFirestore.instance.collection('locations').get();

    setState(() {
      _locations = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'].toString().trim(),
        };
      }).toList();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('Success', style: TextStyle(color: Colors.green)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String locationName) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('Confirm Removal', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove "$locationName"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<bool> _locationHasItems(String locationId) async {
    final query = await FirebaseFirestore.instance
        .collection('locations')
        .doc(locationId)
        .collection('inventory')
        .where('Quantity', isGreaterThan: 0)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> _addToHistory(String locationName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('history').add({
          'username': user.displayName ?? user.email ?? 'Unknown User',
          'action': 'remove_location',
          'toLocation': locationName,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // History logging failed, but don't throw error since main operation succeeded
      print('Failed to log history: $e');
    }
  }

  Future<void> _removeLocation(String locationId, String locationName) async {
    setState(() {
      _isRemoving = true;
    });
    try {
      await FirebaseFirestore.instance.collection('locations').doc(locationId).delete();

      // Add to history after successful removal
      await _addToHistory(locationName);

      setState(() {
        _selectedLocationId = null;
      });
      await fetchLocations();
      _showSuccessDialog('Successfully removed "$locationName"!');
    } catch (e) {
      _showErrorDialog("Error removing location: ${e.toString()}");
    } finally {
      setState(() {
        _isRemoving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: SimpleAppBar(
        title: 'REMOVE LOCATION',
        onBack: () {
          Navigator.pop(context);
        },
        onProfile: () {},
      ),
      backgroundColor: Color(0xFF1E1E1E),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: height * 0.1),
            Text(
              'CHOOSE LOCATION',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.075,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: width * 0.05),
            _locations.isEmpty
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : CustomDropdown(
              value: _selectedLocationId,
              items: _locations,
              width: width,
              onChanged: (val) {
                setState(() {
                  _selectedLocationId = val;
                });
              },
            ),
            const Spacer(),
            Center(
              child: SizedBox(
                width: width * 0.35,
                height: width * 0.125,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _isRemoving
                      ? null
                      : () async {
                    if (_selectedLocationId == null) {
                      _showErrorDialog("Please select a location to remove.");
                      return;
                    }
                    final selectedLoc = _locations.firstWhere(
                            (loc) => loc['id'] == _selectedLocationId);
                    final hasItems = await _locationHasItems(selectedLoc['id']!);
                    if (hasItems) {
                      _showErrorDialog(
                          'Cannot remove "${selectedLoc['name']}". This location still has inventory items.');
                      return;
                    }
                    final confirmed = await _showConfirmationDialog(selectedLoc['name']!);
                    if (confirmed) {
                      await _removeLocation(selectedLoc['id']!, selectedLoc['name']!);
                    }
                  },
                  child: _isRemoving
                      ? CircularProgressIndicator(
                    color: Colors.black,
                  )
                      : Text(
                    "REMOVE",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.05,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: height * 0.08),
          ],
        ),
      ),
    );
  }
}

class CustomDropdown extends StatefulWidget {
  final String? value;
  final List<Map<String, String>> items;
  final Function(String?) onChanged;
  final double width;

  const CustomDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
  }) : super(key: key);

  @override
  _CustomDropdownState createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  bool _isOpen = false;
  late OverlayEntry _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.value != null
                    ? widget.items.firstWhere((item) => item['id'] == widget.value)['name'] ?? 'Select'
                    : 'Select',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: widget.width * 0.045,
                  color: widget.value != null ? Colors.white : Colors.white70,
                ),
              ),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry.remove();
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height),
          child: Material(
            elevation: 4,
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 230),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return ListTile(
                    title: Text(
                      item['name'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: widget.width * 0.045,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      widget.onChanged(item['id']);
                      _closeDropdown();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isOpen) {
      _overlayEntry.remove();
    }
    super.dispose();
  }
}