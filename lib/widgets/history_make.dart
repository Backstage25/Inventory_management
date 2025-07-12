import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventory_management_system/widgets/AppBar.dart';

class HistoryItem {
  final String username;
  final String action;
  final String? fromLocation;
  final String? toLocation;
  final DateTime timestamp;
  final List<Map<String, dynamic>>? items;

  HistoryItem({
    required this.username,
    required this.action,
    this.fromLocation,
    this.toLocation,
    required this.timestamp,
    this.items,
  });

  factory HistoryItem.fromFirestore(Map<String, dynamic> data) {
    return HistoryItem(
      username: data['username'] ?? 'Unknown',
      action: data['action'] ?? 'unknown_action',
      fromLocation: data['fromLocation'],
      toLocation: data['toLocation'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      items: data['items'] != null
          ? List<Map<String, dynamic>>.from(data['items'].map((e) => Map<String, dynamic>.from(e)))
          : null,
    );
  }

  String get description {
    switch (action) {
      case 'add_location':
        return '"$username" added location "$toLocation"';
      case 'remove_location':
        return '"$username" removed location "$toLocation"';
      case 'add_item':
        final item = items?.first;
        return '"$username" added ${item?['quantity']} ${item?['category']}';
      case 'remove_item':
        return '"$username" removed items';
      case 'transfer':
        return '"$username" transferred items from "$fromLocation" to "$toLocation"';
      default:
        return '"$username" performed "$action"';
    }
  }
}

class HistoryMake extends StatelessWidget {
  final List<HistoryItem>? testData;

  const HistoryMake({Key? key, this.testData}) : super(key: key);

  Stream<List<HistoryItem>> getHistoryStream() {
    if (testData != null) {
      return Stream.value(testData!);
    }

    return FirebaseFirestore.instance
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HistoryItem.fromFirestore(doc.data()))
        .toList());
  }
  Widget _buildExpandableTile(HistoryItem item, Size screenSize) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.04,
          vertical: screenSize.height * 0.015,
        ),
        childrenPadding: EdgeInsets.only(
          left: screenSize.width * 0.08,
          bottom: screenSize.height * 0.01,
          right: screenSize.width * 0.04,
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.account_circle, color: Colors.white, size: screenSize.width * 0.07),
            SizedBox(width: screenSize.width * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenSize.width * 0.04,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(item.timestamp),
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: screenSize.width * 0.035,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: item.items?.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 6, color: Colors.white60),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${e['quantity']} ${e['category']}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenSize.width * 0.038,
                  ),
                ),
              ),
            ],
          ),
        )).toList() ?? [],
      ),
    );
  }

  Widget _buildStaticTile(HistoryItem item, Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.height * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_circle, color: Colors.white, size: screenSize.width * 0.07),
          SizedBox(width: screenSize.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.width * 0.04,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(item.timestamp),
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: screenSize.width * 0.035,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: SimpleAppBar(
        title: 'ACTION HISTORY',
        onBack: () {
          Navigator.pop(context);
        },
        onProfile: () {},
      ),
      body: StreamBuilder<List<HistoryItem>>(
        stream: getHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading history', style: TextStyle(color: Colors.red)));
          }

          final historyItems = snapshot.data ?? [];

          if (historyItems.isEmpty) {
            return const Center(
              child: Text('No history yet.', style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: historyItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = historyItems[index];

              final bool showExpandable =
                  item.action == 'transfer' || item.action == 'remove_item';

              return showExpandable
                  ? _buildExpandableTile(item, screenSize)
                  : _buildStaticTile(item, screenSize);
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}