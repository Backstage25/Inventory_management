import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';

class RemoveInventoryPage extends StatefulWidget {
  const RemoveInventoryPage({super.key});

  @override
  State<RemoveInventoryPage> createState() => _RemoveInventoryPageState();
}

class _RemoveInventoryPageState extends State<RemoveInventoryPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  Set<String> allCategories = {};
  String? selectedCategory;
  bool _isLoading = true;
  bool _isRemoving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInventory();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .doc('Auditorium')
          .collection('inventory')
          .get();

      final Set<String> tempCategories = {};
      final items = <Map<String, dynamic>>[];

      for (final doc in invSnapshot.docs) {
        final data = doc.data();

        final category = data['Type'] ?? 'Uncategorized';
        final quantity = (data['Quantity'] ?? 0) as int;
        final itemName = data['Item Name'] ?? 'Unnamed';

        if (quantity > 0) {
          tempCategories.add(category);
          items.add({
            'docId': doc.id,
            'name': itemName,
            'qty': quantity,
            'category': category,
            'removeQty': 0,
          });
        }
      }

      setState(() {
        _allItems = items;
        allCategories = tempCategories;
        _filteredItems = List.from(items);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading inventory: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchesSearch = item['name'].toString().toLowerCase().contains(query) ||
            item['category'].toString().toLowerCase().contains(query);

        final matchesCategory = selectedCategory == null ||
            item['category'] == selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text(
                  'All Categories',
                  style: TextStyle(color: Colors.white),
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
                    style: const TextStyle(color: Colors.white),
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
              })
            ],
          ),
        );
      },
    );
  }

  void _incrementQty(int index) {
    setState(() {
      if (_filteredItems[index]['removeQty'] < _filteredItems[index]['qty']) {
        _filteredItems[index]['removeQty']++;
      }
    });
  }

  void _decrementQty(int index) {
    setState(() {
      if (_filteredItems[index]['removeQty'] > 0) {
        _filteredItems[index]['removeQty']--;
      }
    });
  }

  void _setQuantity(int index, int quantity) {
    setState(() {
      final maxQty = _filteredItems[index]['qty'] as int;
      _filteredItems[index]['removeQty'] = quantity.clamp(0, maxQty);
    });
  }

  // Get current user's username or email
  Future<String> _getCurrentUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try to get display name first, fallback to email
      return user.displayName ?? user.email ?? 'Unknown User';
    }
    return 'Unknown User';
  }

  // Add history entry for item removal
  Future<void> _addHistoryEntry(List<Map<String, dynamic>> removedItems) async {
    try {
      final username = await _getCurrentUsername();

      // Prepare items data for history
      final historyItems = removedItems.map((item) => {
        'name': item['name'],
        'quantity': item['removeQty'],
        'category': item['category'],
      }).toList();

      // Add to history collection
      await FirebaseFirestore.instance.collection('history').add({
        'username': username,
        'action': 'remove_item',
        'fromLocation': 'Auditorium',
        'toLocation': null,
        'timestamp': FieldValue.serverTimestamp(),
        'items': historyItems,
      });
    } catch (e) {
    }
  }

  Future<void> _confirmRemoval() async {
    final itemsToRemove = _filteredItems.where((item) => item['removeQty'] > 0).toList();

    if (itemsToRemove.isEmpty) {
      _showErrorDialog("No items selected for removal.");
      return;
    }

    final confirmed = await _showConfirmationDialog(
      "Are you sure you want to remove ${itemsToRemove.length} item(s)?",
      showDetails: true,
      items: itemsToRemove,
    );

    if (!confirmed) return;

    setState(() {
      _isRemoving = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final item in itemsToRemove) {
        final ref = FirebaseFirestore.instance
            .collection('locations')
            .doc('Auditorium')
            .collection('inventory')
            .doc(item['docId']);

        final int available = item['qty'];
        final int toRemove = item['removeQty'];
        final int updatedQty = available - toRemove;

        if (updatedQty == 0) {
          batch.delete(ref);
        } else {
          batch.update(ref, {'Quantity': updatedQty});
        }
      }

      await batch.commit();

      // Add history entry after successful removal
      await _addHistoryEntry(itemsToRemove);

      _showSuccessDialog("Successfully removed ${itemsToRemove.length} item(s)!");

      // Reload inventory after successful removal
      await _loadInventory();

    } catch (e) {
      _showErrorDialog("Error removing items: ${e.toString()}");
    } finally {
      setState(() {
        _isRemoving = false;
      });
    }
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

  Future<bool> _showConfirmationDialog(
      String message, {
        bool showDetails = false,
        List<Map<String, dynamic>>? items,
      }) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('Confirm Removal', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(color: Colors.white70)),
            if (showDetails && items != null) ...[
              const SizedBox(height: 16),
              const Text('Items to be removed:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${item['name']}: ${item['removeQty']} units',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              )),
            ],
          ],
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
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 480;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: SimpleAppBar(
        title: 'REMOVE ITEMS',
        onBack: () {
          Navigator.pop(context);
        },
        onProfile: () {},
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth > 1200
              ? 40.0
              : constraints.maxWidth > 800
              ? 32.0
              : constraints.maxWidth > 600
              ? 24.0
              : 16.0;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Column(
              children: [
                _buildSearchAndFilterRow(constraints),
                // Show active filter
                if (selectedCategory != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Chip(
                          label: Text(
                            selectedCategory!,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF3C3C3C),
                          deleteIcon: const Icon(Icons.close, color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onDeleted: () {
                            setState(() {
                              selectedCategory = null;
                            });
                            _filterItems();
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (_errorMessage != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadInventory,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_filteredItems.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              _allItems.isEmpty ? "No inventory available." : "No items match your search.",
                              style: const TextStyle(color: Colors.white70, fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                            if (_allItems.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    selectedCategory = null;
                                  });
                                  _filterItems();
                                },
                                child: const Text('Clear filters', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(child: _buildItemList(constraints)),
                const SizedBox(height: 20),
                _buildActionButtons(constraints),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilterRow(BoxConstraints constraints) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      children: [
        Expanded(
          child: TextField(
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              color: Colors.white,
            ),
            controller: _searchController,
            cursorColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2E2E2E),
              hintText: 'Search',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  _searchController.clear();
                  _filterItems();
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 56, // Standard TextField height
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _showCategoryFilter,
            icon: Icon(
              Icons.filter_list,
              color: selectedCategory != null ? Colors.blue : Colors.white54,
              size: 24,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildItemList(BoxConstraints constraints) {
    final isMobile = constraints.maxWidth < 480;
    final isTablet = constraints.maxWidth > 600;
    final cardPadding = isMobile ? 12.0 : 16.0;
    final titleFontSize = isMobile ? 16.0 : isTablet ? 22.0 : 20.0;
    final subtitleFontSize = isMobile ? 12.0 : 14.0;

    return ListView.builder(
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final isSelected = item['removeQty'] > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3E3E3E) : const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Colors.white54, width: 1)
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Roboto',
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Category: ${item['category']}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: subtitleFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Available: ${item['qty']}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: subtitleFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remove: ${item['removeQty']}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: isMobile ? 14.0 : 16.0,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    _buildQuantityControls(index, isMobile),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantityControls(int index, bool isMobile) {
    final item = _filteredItems[index];
    final buttonSize = isMobile ? 28.0 : 32.0;
    final quantityWidth = isMobile ? 40.0 : 50.0;
    final iconSize = isMobile ? 16.0 : 20.0;
    final fontSize = isMobile ? 14.0 : 16.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minus button
        GestureDetector(
          onTap: () => _decrementQty(index),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white54, width: 1),
            ),
            child: Icon(
              Icons.remove,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Editable quantity field
        GestureDetector(
          onTap: () => _showQuantityDialog(index),
          child: Container(
            width: quantityWidth,
            height: buttonSize,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white54, width: 1),
            ),
            child: Center(
              child: Text(
                '${item['removeQty']}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Plus button
        GestureDetector(
          onTap: () => _incrementQty(index),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white54, width: 1),
            ),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BoxConstraints constraints) {
    final selectedCount = _filteredItems.where((item) => item['removeQty'] > 0).length;
    final isMobile = constraints.maxWidth < 480;
    final buttonHeight = isMobile ? 44.0 : 48.0;
    final fontSize = isMobile ? 14.0 : 16.0;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: _buildButton(
              label: 'CLEAR ALL',
              filled: false,
              onPressed: selectedCount > 0 ? _clearAllSelections : null,
              fontSize: fontSize,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: _buildButton(
              label: _isRemoving ? 'REMOVING...' : 'CONFIRM ($selectedCount)',
              filled: true,
              onPressed: _isRemoving ? null : _confirmRemoval,
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required bool filled,
    required double fontSize,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: filled ? Colors.black : Colors.white,
        backgroundColor: filled ? Colors.white : Colors.transparent,
        disabledForegroundColor: Colors.white60,
        disabledBackgroundColor: filled ? Colors.white60 : Colors.transparent,
        side: filled ? null : const BorderSide(color: Colors.white),
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label),
    );
  }

  void _clearAllSelections() {
    setState(() {
      for (var item in _filteredItems) {
        item['removeQty'] = 0;
      }
    });
  }

  void _showQuantityDialog(int index) {
    final item = _filteredItems[index];
    final controller = TextEditingController(text: item['removeQty'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: Text(
          'Set Quantity for ${item['name']}',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter quantity (max: ${item['qty']})',
            hintStyle: const TextStyle(color: Colors.white60),
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text) ?? 0;
              _setQuantity(index, quantity);
              Navigator.pop(context);
            },
            child: const Text('Set', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}