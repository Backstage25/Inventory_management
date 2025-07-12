import 'package:flutter/material.dart';
import 'package:inventory_management_system/functions/Remove_Inventory.dart';
import 'package:inventory_management_system/screens/Dashboard.dart';
import 'package:inventory_management_system/widgets/Dashboard_Button.dart';
import 'package:inventory_management_system/functions/Add_Items.dart';
import 'package:inventory_management_system/functions/Remove_Location.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';

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
                )
              ],
            ),
          )
      ),
    );
  }
}
