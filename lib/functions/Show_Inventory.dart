import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';

class ShowInventory extends StatefulWidget {
  const ShowInventory({super.key});

  @override
  State<ShowInventory> createState() => _ShowInventoryState();
}

class _ShowInventoryState extends State<ShowInventory> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String? selectedCategory;
  Map<String, Map<String, Map<String, dynamic>>> inventoryData = {}; // Updated structure
  Set<String> allCategories = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    try {
      final locationsSnapshot =
      await FirebaseFirestore.instance.collection('locations').get();

      final Map<String, Map<String, Map<String, dynamic>>> tempData = {};
      final Set<String> tempCategories = {};

      for (final locDoc in locationsSnapshot.docs) {
        final invSnapshot = await FirebaseFirestore.instance
            .collection('locations')
            .doc(locDoc.id)
            .collection('inventory')
            .get();

        if (invSnapshot.docs.isNotEmpty) {
          tempData[locDoc.id] = {};
          for (final itemDoc in invSnapshot.docs) {
            final data = itemDoc.data();

            final itemName = data['Item Name'];
            final quantity = data['Quantity'] ?? 0;
            final category = data['Type'] ?? 'Uncategorized'; // Use 'Type' field specifically

            if (itemName != null && quantity > 0) {
              tempData[locDoc.id]![itemName] = {
                'quantity': quantity,
                'category': category,
              };
              tempCategories.add(category);
            }
          }
        }
      }

      setState(() {
        inventoryData = tempData;
        allCategories = tempCategories;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Filter data based on search query and selected category
    final filteredData = inventoryData.entries.where((entry) {
      final locationName = entry.key.toLowerCase();
      final matchesLocation = locationName.contains(searchQuery.toLowerCase());

      // Check if any item matches the search query and category filter
      final matchesItem = entry.value.entries.any((itemEntry) {
        final itemName = itemEntry.key.toLowerCase();
        final itemCategory = itemEntry.value['category'] as String;

        final matchesSearch = itemName.contains(searchQuery.toLowerCase()) ||
            itemCategory.toLowerCase().contains(searchQuery.toLowerCase());

        final matchesCategory = selectedCategory == null ||
            itemCategory == selectedCategory;

        return matchesSearch && matchesCategory;
      });

      return matchesLocation || matchesItem;
    }).map((entry) {
      // Filter items within each location based on category
      final filteredItems = <String, Map<String, dynamic>>{};

      for (final itemEntry in entry.value.entries) {
        final itemName = itemEntry.key.toLowerCase();
        final itemCategory = itemEntry.value['category'] as String;

        final matchesSearch = itemName.contains(searchQuery.toLowerCase()) ||
            itemCategory.toLowerCase().contains(searchQuery.toLowerCase()) ||
            entry.key.toLowerCase().contains(searchQuery.toLowerCase());

        final matchesCategory = selectedCategory == null ||
            itemCategory == selectedCategory;

        if (matchesSearch && matchesCategory) {
          filteredItems[itemEntry.key] = itemEntry.value;
        }
      }

      return MapEntry(entry.key, filteredItems);
    }).where((entry) => entry.value.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: SimpleAppBar(
        title: 'SHOW INVENTORY',
        onBack: () {
          Navigator.pop(context);
        },
        onProfile: () {},
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.only(top: screenWidth * 0.1),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(fontSize: screenWidth * 0.05),
                      controller: _searchController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF2E2E2E),
                        hintText: 'Search',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              searchQuery = "";
                            });
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _showCategoryFilter,
                    icon: Icon(
                      Icons.filter_list,
                      color: selectedCategory != null ? Colors.blue : Colors.white54,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF2E2E2E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Show active filter
            if (selectedCategory != null)
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenWidth * 0.025,
                ),
                child: Row(
                  children: [
                    Chip(
                      label: Text(
                        '$selectedCategory',
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
                      },
                    ),
                  ],
                ),
              ),
            SizedBox(height: screenWidth * 0.04),
            Expanded(
              child: filteredData.isEmpty
                  ? Center(
                child: Text(
                  "No inventory matches your search.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenWidth * 0.05,
                  ),
                ),
              )
                  : ListView(
                children: filteredData.map((entry) {
                  return Card(
                    color: const Color(0xFF2E2E2E),
                    margin: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.025,
                        horizontal: screenWidth * 0.05),
                    child: ExpansionTile(
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: screenWidth * 0.0625,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: entry.value.entries.map((itemEntry) {
                        final itemData = itemEntry.value;
                        return ListTile(
                          title: Text(
                            itemEntry.key,
                            style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'Category: ${itemData['category']}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.white70,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Text(
                              itemData['quantity'].toString(),
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}