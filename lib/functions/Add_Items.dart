import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory_management_system/screens/Dashboard_Admin.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';

class AddItemsPage extends StatefulWidget {
  const AddItemsPage({super.key});

  @override
  State<AddItemsPage> createState() => _AddItemsPageState();
}

class _AddItemsPageState extends State<AddItemsPage> {
  final TextEditingController itemNameController = TextEditingController();
  int quantity = 1;
  String? selectedItemType;
  String? selectedLocation;

  final List<String> itemTypes = [
    'Microphones',
    'Cables',
    'Speakers',
    'Mixers',
    'Miscellaneous',
  ];

  List<String> locations = [];
  bool isLoadingLocations = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    final snapshot = await FirebaseFirestore.instance.collection('locations').get();
    setState(() {
      locations = snapshot.docs.map((doc) => doc.id).toList();
      isLoadingLocations = false;
    });
  }

  bool _validateInputs() {
    return itemNameController.text.isNotEmpty &&
        selectedItemType != null &&
        selectedLocation != null &&
        quantity > 0;
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

  Future<bool> _showConfirmationDialog() async {
    final screenWidth = MediaQuery.of(context).size.width;
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: Text('Confirm Addition', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.055)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to add the following item?',
              style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.045),
            ),
            SizedBox(height: screenWidth * 0.025),
            Text('Item Name: ${itemNameController.text}', style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.043)),
            Text('Item Type: $selectedItemType', style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.043)),
            Text('Location: $selectedLocation', style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.043)),
            Text('Quantity: $quantity', style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.043)),
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

  Future<void> _addItemToFirestore() async {
    setState(() => _isProcessing = true);
    final docId = '${itemNameController.text.trim()}_${selectedItemType!.trim()}';
    final docRef = FirebaseFirestore.instance
        .collection('locations')
        .doc(selectedLocation)
        .collection('inventory')
        .doc(docId);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      // Item already exists — update quantity
      final currentQty = docSnapshot.data()?['Quantity'] ?? 0;
      await docRef.update({
        'Quantity': currentQty + quantity,
      });
    } else {
      await docRef.set({
        'Item Name': itemNameController.text,
        'Type': selectedItemType,
        'Quantity': quantity,
      });
    }

    setState(() => _isProcessing = false);
    _showSuccessDialog('Added Successfully!');
  }

  Future<void> _onAddPressed() async {
    if (!_validateInputs()) {
      _showErrorDialog("Please fill all fields with valid values.");
      return;
    }

    final confirmed = await _showConfirmationDialog();

    if (confirmed) {
      await _addItemToFirestore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive scaling
    double scaleW(double px) => px / 440.0 * screenWidth;
    double scaleH(double px) => px / 956.0 * screenHeight;
    double fontScale(double px) => px / 440.0 * screenWidth;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: SimpleAppBar(
        title: 'ADD ITEMS',
        onBack: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardAdmin()),
          );
        },
        onProfile: () {},
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: scaleW(32),
            vertical: scaleH(40),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('ITEM NAME', fontScale),
              SizedBox(height: scaleH(6)),
              _buildTextField(controller: itemNameController, fontScale: fontScale),

              SizedBox(height: scaleH(40)),

              _buildLabel('ITEM TYPE', fontScale),
              SizedBox(height: scaleH(6)),
              _buildCustomDropdown(
                items: itemTypes,
                value: selectedItemType,
                onChanged: (value) => setState(() => selectedItemType = value),
                width: screenWidth,
                fontScale: fontScale,
              ),

              SizedBox(height: scaleH(40)),

              _buildLabel('LOCATION', fontScale),
              SizedBox(height: scaleH(6)),
              isLoadingLocations
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCustomDropdown(
                items: locations,
                value: selectedLocation,
                onChanged: (value) => setState(() => selectedLocation = value),
                width: screenWidth,
                fontScale: fontScale,
              ),

              SizedBox(height: scaleH(40)),

              _buildLabel('QUANTITY', fontScale),
              SizedBox(height: scaleH(6)),
              _buildQuantityInput(fontScale: fontScale),
              SizedBox(height: scaleH(60)),

              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: scaleW(120),
                  height: scaleH(48),
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _onAddPressed,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: fontScale(18),
                      ),
                    ),
                    child: _isProcessing
                        ? SizedBox(
                      width: fontScale(24),
                      height: fontScale(24),
                      child: const CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                        : Text('Add', style: TextStyle(fontSize: fontScale(18))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, double Function(double) fontScale) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: fontScale(24),
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required double Function(double) fontScale}) {
    return SizedBox(
      height: fontScale(53),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: fontScale(24),
          color: Colors.white,
        ),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: 'Enter item name...',
          hintStyle: TextStyle(
            color: Colors.white54,
            fontFamily: 'Roboto',
            fontSize: fontScale(20),
          ),
          filled: true,
          fillColor: const Color(0xFF2E2E2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: fontScale(12)),
        ),
      ),
    );
  }

  Widget _buildQuantityInput({required double Function(double) fontScale}) {
    return Container(
      height: fontScale(53),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: EdgeInsets.symmetric(horizontal: fontScale(12)),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: Colors.white, size: fontScale(24)),
            onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$quantity',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: fontScale(24),
                  color: Colors.white,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white, size: fontScale(24)),
            onPressed: () => setState(() => quantity++),
          ),
        ],
      ),
    );
  }

  // Custom dropdown like RemoveLoc page, always opens below
  Widget _buildCustomDropdown({
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    required double width,
    required double Function(double) fontScale,
  }) {
    return _CustomDropdown(
      items: items,
      value: value,
      onChanged: onChanged,
      width: width,
      fontScale: fontScale,
    );
  }
}

// --- Custom Dropdown Widget ---

class _CustomDropdown extends StatefulWidget {
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final double width;
  final double Function(double) fontScale;

  const _CustomDropdown({
    Key? key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.width,
    required this.fontScale,
  }) : super(key: key);

  @override
  __CustomDropdownState createState() => __CustomDropdownState();
}

class __CustomDropdownState extends State<_CustomDropdown> {
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
          height: widget.fontScale(53),
          padding: EdgeInsets.symmetric(horizontal: widget.fontScale(12)),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.value ?? 'Select',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: widget.fontScale(20),
                  color: widget.value != null ? Colors.white : Colors.white70,
                ),
              ),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.white,
                size: widget.fontScale(28),
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
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: Material(
          elevation: 4,
          color: const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(6),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.fontScale(230)),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = item == widget.value;
                return ListTile(
                  title: Text(
                    item,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: widget.fontScale(20),
                    ),
                  ),
                  onTap: () {
                    widget.onChanged(item);
                    _closeDropdown();
                  },
                );
              },
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
