import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/Dashboard_Admin.dart';
import 'Confirm_Items.dart';
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

  List<String> itemTypes = [
    'Microphones',
    'Cables',
    'Speakers',
    'Mixers',
    'Miscellaneous',
  ];

  List<String> locations = [];
  bool isLoadingLocations = true;

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const designWidth = 440.0;
    const designHeight = 956.0;

    double scaleW(double px) => px / designWidth * screenWidth;
    double scaleH(double px) => px / designHeight * screenHeight;

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
              _buildLabel('ITEM NAME'),
              SizedBox(height: scaleH(6)),
              _buildTextField(controller: itemNameController),

              SizedBox(height: scaleH(40)),

              _buildLabel('ITEM TYPE'),
              SizedBox(height: scaleH(6)),
              _buildDropdownField(
                items: itemTypes,
                value: selectedItemType,
                onChanged: (value) => setState(() => selectedItemType = value),
              ),

              SizedBox(height: scaleH(40)),

              _buildLabel('LOCATION'),
              SizedBox(height: scaleH(6)),
              isLoadingLocations
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDropdownField(
                items: locations,
                value: selectedLocation,
                onChanged: (value) => setState(() => selectedLocation = value),
              ),

              SizedBox(height: scaleH(40)),

              _buildLabel('QUANTITY'),
              SizedBox(height: scaleH(6)),
              _buildQuantityInput(),
              SizedBox(height: scaleH(60)),

              Align(
                alignment: Alignment.centerRight,
                child: _buildButton(
                  label: 'Next',
                  onPressed: _validateInputs()
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConfirmItemsPage(
                          itemName: itemNameController.text,
                          itemType: selectedItemType!,
                          location: selectedLocation!,
                          quantity: quantity,
                        ),
                      ),
                    );
                  }
                      : null,
                  filled: true,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  bool _validateInputs() {
    return itemNameController.text.isNotEmpty &&
        selectedItemType != null &&
        selectedLocation != null &&
        quantity > 0;
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller}) {
    return SizedBox(
      height: 53,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 24,
          color: Colors.white,
        ),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF2E2E2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 53,
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: const Color(0xFF2E2E2E),
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 24,
            color: Colors.white,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(item),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          menuMaxHeight: 48.0 * 5,
        ),
      ),
    );
  }

  Widget _buildQuantityInput() {
    return Container(
      height: 53,
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => setState(() => quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback? onPressed,
    required bool filled,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: filled ? Colors.black : Colors.white,
        backgroundColor: filled ? Colors.white : Colors.transparent,
        side: filled ? null : const BorderSide(color: Colors.white),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(label),
    );
  }
}
