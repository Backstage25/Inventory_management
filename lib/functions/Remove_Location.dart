import 'package:flutter/material.dart';
import 'package:inventory_management_system/functions/Confirm_RemoveLoc.dart';
import 'package:inventory_management_system/screens/Dashboard_Admin.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RemoveLoc extends StatefulWidget {
  @override
  _RemoveLocState createState() => _RemoveLocState();
}

class _RemoveLocState extends State<RemoveLoc> {
  String? _selectedLocationId;
  List<Map<String, String>> _locations = [];

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

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

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
      backgroundColor: Colors.grey[900],
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
                  fontSize: width * 0.075 ,
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
                  onPressed: _selectedLocationId == null
                      ? null
                      : () async {
                    final selectedLoc = _locations.firstWhere(
                            (loc) => loc['id'] == _selectedLocationId);

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConfirmRemoveScreen(
                          locationId: selectedLoc['id']!,
                          locationName: selectedLoc['name']!,
                        ),
                      ),
                    );

                    if (result == true) {
                      setState(() {
                        _selectedLocationId = null;
                      });

                      await fetchLocations();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Center(
                            child: Text(
                              'REMOVED SUCCESSFULLY!',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          backgroundColor: Colors.black,
                          behavior: SnackBarBehavior.floating,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          margin: EdgeInsets.only(
                            bottom:
                            MediaQuery.of(context).size.height * 0.08,
                            left: MediaQuery.of(context).size.width * 0.2,
                            right:
                            MediaQuery.of(context).size.width * 0.2,
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text(
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
            SizedBox(height: height * 0.04),
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
              constraints: const BoxConstraints(maxHeight: 200),
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
