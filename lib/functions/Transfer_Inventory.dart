import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransferInventoryPage extends StatefulWidget {
  const TransferInventoryPage({super.key});

  @override
  State<TransferInventoryPage> createState() => _TransferInventoryPageState();
}

class _TransferInventoryPageState extends State<TransferInventoryPage> {
  String? fromLocation;
  String? toLocation;
  List<String> locationNames = [];
  Map<String, int> cart = {}; // itemId -> qty
  Map<String, Map<String, dynamic>> cartDetails = {}; // itemId -> item details

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    final snapshot = await FirebaseFirestore.instance.collection('locations').get();
    setState(() {
      locationNames = snapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  Future<void> _selectItems() async {
    if (fromLocation == null) return;
    final result = await Navigator.push<Map<String, int>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectItemsScreen(
          fromLocation: fromLocation!,
          initialCart: cart,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        cart = result;
      });
      await _fetchCartDetails();
    }
  }

  Future<void> _fetchCartDetails() async {
    if (fromLocation == null || cart.isEmpty) return;
    final inventoryRef = FirebaseFirestore.instance
        .collection('locations')
        .doc(fromLocation)
        .collection('inventory');

    final Map<String, Map<String, dynamic>> details = {};
    for (final itemId in cart.keys) {
      final doc = await inventoryRef.doc(itemId).get();
      if (doc.exists) {
        details[itemId] = doc.data()!;
      }
    }
    setState(() {
      cartDetails = details;
    });
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

  void _showSuccessDialog(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
        title: Text(
          'Success',
          style: TextStyle(
            color: Colors.green,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.055,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w500,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() {
                fromLocation = null;
                toLocation = null;
                cart = {};
                cartDetails = {};
              });
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.045,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTransferConfirmation() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
        title: Text(
          'Confirm Transfer',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.055,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to transfer the following items?',
              style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.045),
            ),
            SizedBox(height: screenWidth * 0.025),
            ...cart.entries.map((entry) {
              final details = cartDetails[entry.key];
              return Text(
                '${details?['Item Name'] ?? entry.key} - ${entry.value}',
                style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045),
              );
            }),
            SizedBox(height: screenWidth * 0.025),
            Text('From: $fromLocation', style: TextStyle(color: Colors.white54, fontSize: screenWidth * 0.04)),
            Text('To: $toLocation', style: TextStyle(color: Colors.white54, fontSize: screenWidth * 0.04)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Transfer', style: TextStyle(color: Colors.blue, fontSize: screenWidth * 0.045)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      await _transferItems();
    }
  }

  Future<void> _transferItems() async {
    setState(() {
      _isProcessing = true;
    });

    final fromRef = FirebaseFirestore.instance.collection('locations').doc(fromLocation).collection('inventory');
    final toRef = FirebaseFirestore.instance.collection('locations').doc(toLocation).collection('inventory');
    final batch = FirebaseFirestore.instance.batch();

    try {
      // For each item in cart, decrement from 'from', increment at 'to'
      for (final entry in cart.entries) {
        final itemId = entry.key;
        final qty = entry.value;

        // Get item details from cartDetails
        final details = cartDetails[itemId];
        if (details == null) continue;

        // Update fromLocation
        final fromDocRef = fromRef.doc(itemId);
        final fromQty = details['Quantity'] ?? 0;
        final newFromQty = fromQty - qty;
        if (newFromQty > 0) {
          batch.update(fromDocRef, {'Quantity': newFromQty});
        } else {
          batch.delete(fromDocRef);
        }

        // Update toLocation
        final toDocRef = toRef.doc(itemId);
        final toDocSnap = await toDocRef.get();
        if (toDocSnap.exists) {
          final toQty = toDocSnap.data()?['Quantity'] ?? 0;
          batch.update(toDocRef, {'Quantity': toQty + qty});
        } else {
          batch.set(toDocRef, {
            'Item Name': details['Item Name'],
            'Type': details['Type'],
            'Quantity': qty,
          });
        }
      }

      await batch.commit();

      final currentUser = FirebaseAuth.instance.currentUser?.displayName; // Replace with actual user
      final historyEntry = {
        'username': currentUser,
        'action': 'transfer',
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'timestamp': FieldValue.serverTimestamp(),
        'items': cart.entries.map((entry) {
          final itemId = entry.key;
          final qty = entry.value;
          final itemName = cartDetails[itemId]?['Item Name'] ?? 'Unknown';
          return {'name': itemName, 'quantity': qty};
        }).toList(),
      };

      await FirebaseFirestore.instance.collection('history').add(historyEntry);

      setState(() {
        _isProcessing = false;
      });
      _showSuccessDialog("Transferred Successfully!");
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Error during transfer: $e');
    }
  }

  Widget _buildCartSection(double screenWidth, double screenHeight) {
    return Container(
      height: screenHeight * 0.35,
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cart",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.05,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, idx) {
                final entry = cart.entries.elementAt(idx);
                final details = cartDetails[entry.key];
                final maxQty = details?['Quantity'] ?? entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        details?['Item Name'] ?? entry.key,
                        style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove, color: Colors.white, size: screenWidth * 0.055),
                      onPressed: entry.value > 1
                          ? () => setState(() => cart[entry.key] = entry.value - 1)
                          : null,
                    ),
                    Text("${entry.value}", style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04)),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.white, size: screenWidth * 0.055),
                      onPressed: entry.value < maxQty
                          ? () => setState(() => cart[entry.key] = entry.value + 1)
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: screenWidth * 0.055),
                      onPressed: () => setState(() {
                        cart.remove(entry.key);
                        cartDetails.remove(entry.key);
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: SimpleAppBar(
        title: 'TRANSFER ITEMS',
        onBack: () {
          Navigator.pop(context);
        },
        onProfile: () {},
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'From Location',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            _CustomDropdown(
              value: fromLocation,
              items: locationNames,
              width: screenWidth,
              onChanged: (val) {
                if (val != toLocation) {
                  setState(() {
                    fromLocation = val;
                    cart = {};
                    cartDetails = {};
                  });
                }
              },
            ),
            SizedBox(height: screenHeight * 0.03),
            ElevatedButton(
              onPressed: fromLocation != null ? _selectItems : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.015),
                ),
                minimumSize: Size(double.infinity, screenHeight * 0.06),
              ),
              child: Text(
                "Select Items",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.045,
                ),
              ),
            ),
            cart.isNotEmpty
                ? _buildCartSection(screenWidth, screenHeight)
                : SizedBox(height: screenHeight * 0.03),
            Text(
              'To Location',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            _CustomDropdown(
              value: toLocation,
              items: locationNames.where((loc) => loc != fromLocation).toList(),
              width: screenWidth,
              onChanged: (val) {
                setState(() {
                  toLocation = val;
                });
              },
            ),
            SizedBox(height: screenHeight * 0.05),
            Center(
              child: SizedBox(
                width: screenWidth * 0.5,
                height: screenHeight * 0.06,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                    if (fromLocation == null ||
                        toLocation == null ||
                        cart.isEmpty) {
                      _showErrorDialog("Please fill all details and select items to transfer.");
                    } else if (fromLocation == toLocation) {
                      _showErrorDialog("From and To locations cannot be the same.");
                    } else {
                      _showTransferConfirmation();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.015),
                    ),
                    textStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.05,
                    ),
                  ),
                  child: _isProcessing
                      ? SizedBox(
                    width: screenWidth * 0.06,
                    height: screenWidth * 0.06,
                    child: const CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                  )
                      : const Text('TRANSFER'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Dropdown Widget (responsive) ---
class _CustomDropdown extends StatefulWidget {
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final double width;

  const _CustomDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
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
          height: widget.width * 0.12,
          padding: EdgeInsets.symmetric(horizontal: widget.width * 0.03),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(widget.width * 0.025),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.value ?? 'Select',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: widget.width * 0.045,
                  color: widget.value != null ? Colors.white : Colors.white70,
                ),
              ),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.white,
                size: widget.width * 0.08,
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
          borderRadius: BorderRadius.circular(widget.width * 0.025),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.width * 0.6),
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
                      fontSize: widget.width * 0.045,
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

// --- Select Items Screen (responsive) ---
class SelectItemsScreen extends StatefulWidget {
  final String fromLocation;
  final Map<String, int>? initialCart;

  const SelectItemsScreen({Key? key, required this.fromLocation, this.initialCart}) : super(key: key);

  @override
  State<SelectItemsScreen> createState() => _SelectItemsScreenState();
}

class _SelectItemsScreenState extends State<SelectItemsScreen> {
  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  Map<String, int> selectedQuantities = {};
  TextEditingController searchController = TextEditingController();
  Set<String> allCategories = {};
  String? selectedCategory;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItems();
    searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchItems() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.fromLocation)
        .collection('inventory')
        .get();

    final items = snapshot.docs
        .where((doc) => (doc['Quantity'] ?? 0) > 0)
        .map((doc) {
      final type = doc['Type'] ?? 'Uncategorized';
      allCategories.add(type);
      return {
        'id': doc.id,
        'name': doc['Item Name'] ?? doc.id,
        'type': type,
        'qty': doc['Quantity'] ?? 0,
      };
    })
        .toList();

    setState(() {
      allItems = items;
      filteredItems = List.from(allItems);
      if (widget.initialCart != null) {
        selectedQuantities = Map<String, int>.from(widget.initialCart!);
      }
      isLoading = false;
    });
  }

  void _filterItems() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredItems = allItems.where((item) {
        final matchesSearch = item['name'].toString().toLowerCase().contains(query) ||
            item['type'].toString().toLowerCase().contains(query);
        final matchesCategory =
            selectedCategory == null || item['type'] == selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _showCategoryFilter() {
    final screenWidth = MediaQuery.of(context).size.width;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.04)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              ListTile(
                title: Text(
                  'All Categories',
                  style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045),
                ),
                leading: Radio<String?>(
                  value: null,
                  groupValue: selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                    _filterItems();
                    Navigator.pop(context);
                  },
                ),
              ),
              ...allCategories.map((category) {
                return ListTile(
                  title: Text(
                    category,
                    style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045),
                  ),
                  leading: Radio<String?>(
                    value: category,
                    groupValue: selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                      _filterItems();
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _addAllItems() {
    setState(() {
      for (final item in filteredItems) {
        selectedQuantities[item['id']] = item['qty'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text("SELECT ITEMS TO TRANSFER", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.045),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF2E2E2E),
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.white54, fontSize: screenWidth * 0.045),
                      prefixIcon: Icon(Icons.search, color: Colors.white54, size: screenWidth * 0.06),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.white54, size: screenWidth * 0.06),
                        onPressed: () {
                          searchController.clear();
                          _filterItems();
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (query) => _filterItems(),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Container(
                  height: screenWidth * 0.12,
                  width: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    color: Color(0xFF2E2E2E),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.filter_list, color: selectedCategory != null ? Colors.blue : Colors.white54, size: screenWidth * 0.06),
                    onPressed: _showCategoryFilter,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.01),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: filteredItems.isNotEmpty ? _addAllItems : null,
                child: Text("Add All Items", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
              ),
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
              child: Text(
                "No items found.",
                style: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.05),
              ),
            )
                : ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final selectedQty = selectedQuantities[item['id']] ?? 0;
                return Container(
                  margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02, horizontal: screenWidth * 0.04),
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    border: selectedQty > 0
                        ? Border.all(color: Colors.blueAccent, width: 1)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'],
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.w500)),
                      SizedBox(height: screenHeight * 0.005),
                      Text('Type: ${item['type']}',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.04)),
                      SizedBox(height: screenHeight * 0.005),
                      Text('Available: ${item['qty']}',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: screenWidth * 0.04)),
                      SizedBox(height: screenHeight * 0.01),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, color: Colors.white, size: screenWidth * 0.055),
                            onPressed: selectedQty > 0
                                ? () {
                              setState(() {
                                selectedQuantities[item['id']] = selectedQty - 1;
                                if (selectedQuantities[item['id']] == 0) {
                                  selectedQuantities.remove(item['id']);
                                }
                              });
                            }
                                : null,
                          ),
                          SizedBox(
                            width: screenWidth * 0.09,
                            child: Center(
                              child: Text(
                                selectedQty.toString(),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.045),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.white, size: screenWidth * 0.055),
                            onPressed: selectedQty < item['qty']
                                ? () {
                              setState(() {
                                selectedQuantities[item['id']] = selectedQty + 1;
                              });
                            }
                                : null,
                          ),
                          TextButton(
                            onPressed: selectedQty < item['qty']
                                ? () {
                              setState(() {
                                selectedQuantities[item['id']] = item['qty'];
                              });
                            }
                                : null,
                            child: Text('All', style: TextStyle(color: Colors.blue, fontSize: screenWidth * 0.04)),
                          ),
                          Spacer(),
                          if (selectedQty > 0)
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red, size: screenWidth * 0.055),
                              onPressed: () {
                                setState(() {
                                  selectedQuantities.remove(item['id']);
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: Size.fromHeight(screenHeight * 0.06),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.025)),
              ),
              onPressed: selectedQuantities.isNotEmpty
                  ? () {
                Navigator.pop(context, selectedQuantities);
              }
                  : null,
              child: Text(
                "Add to Cart",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
