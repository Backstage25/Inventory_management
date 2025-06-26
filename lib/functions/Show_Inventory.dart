import 'package:flutter/material.dart';
import 'package:inventory_management_system/screens/Dashboard.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';

class ShowInventory extends StatefulWidget {
  const ShowInventory({super.key});

  @override
  State<ShowInventory> createState() => _ShowInventoryState();
}

class _ShowInventoryState extends State<ShowInventory> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  final Map<String, Map<String, int>> inventoryData = {
    "AUDITORIUM": {
      "XLR Cables": 3,
      "5 - 5 Cables": 4,
      "Stereo → 3.5": 2,
      "Yamaha D8R": 1,
      "Yamaha D2R": 2,
      "Power Cables": 3,
    },
    "AH1 104": {
      "XLR Cables": 2,
      "5 - 5 Cables": 1,
      "Stereo → 3.5": 1,
      "Yamaha D8R": 0,
      "Yamaha D2R": 1,
      "Power Cables": 2,
    },
    "CC LAB": {
      "XLR Cables": 5,
      "5 - 5 Cables": 3,
      "Stereo → 3.5": 2,
      "Yamaha D8R": 1,
      "Yamaha D2R": 1,
      "Power Cables": 1,
    },
    "SAC": {
      "XLR Cables": 1,
      "5 - 5 Cables": 2,
      "Stereo → 3.5": 1,
      "Yamaha D8R": 1,
      "Yamaha D2R": 1,
      "Power Cables": 1,
    },
    "FOOD KING": {
      "XLR Cables": 2,
      "5 - 5 Cables": 2,
      "Stereo → 3.5": 2,
      "Yamaha D8R": 0,
      "Yamaha D2R": 1,
      "Power Cables": 2,
    },
  };

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final filteredData = inventoryData.entries.where((entry) {
      final locationName = entry.key.toLowerCase();
      final matchesLocation = locationName.contains(searchQuery.toLowerCase());

      final matchesItem = entry.value.keys.any((item) =>
          item.toLowerCase().contains(searchQuery.toLowerCase()));

      return matchesLocation || matchesItem;
    }).toList();

    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
      appBar: SimpleAppBar(
        title: 'SHOW INVENTORY',
        onBack: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        },
        onProfile: () {},
      ),
      body: Padding(
        padding: EdgeInsets.only(top: screenWidth * 0.1), // Space below AppBar
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF2E2E2E),
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
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
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            SizedBox(height: screenWidth * 0.1), // Spacing between search bar and list
            Expanded(
              child: ListView(
                children: filteredData.map((entry) {
                  return Card(
                    color: Color(0xFF2E2E2E),
                    margin: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.025, horizontal: screenWidth * 0.05),
                    child: ExpansionTile(
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: screenWidth * 0.0625
                        ),
                      ),
                      children: entry.value.entries.map((itemEntry) {
                        return ListTile(
                          title: Text(
                            itemEntry.key,
                            style: TextStyle(
                                fontSize: screenWidth * 0.05
                            ),
                          ),
                          trailing: Text(
                            itemEntry.value.toString(),
                            style: TextStyle(
                                fontSize: screenWidth * 0.05
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