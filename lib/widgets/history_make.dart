import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          ? List<Map<String, dynamic>>.from(
          data['items'].map((e) => Map<String, dynamic>.from(e)))
          : null,
    );
  }

  String get description {
    switch (action) {
      case 'add_location':
        return '$username added location $toLocation';
      case 'remove_location':
        return '$username removed location $toLocation';
      case 'add_item':
        final item = items?.first;
        return '$username added ${item?['quantity']} ${item?['name']}';
      case 'remove_item':
        return '$username removed items';
      case 'transfer':
        return '$username transferred items from $fromLocation to $toLocation';
      default:
        return '$username performed $action';
    }
  }
}

class HistoryMake extends StatefulWidget {
  final List<HistoryItem>? testData;
  const HistoryMake({Key? key, this.testData}) : super(key: key);

  @override
  State<HistoryMake> createState() => _HistoryMakeState();
}

class _HistoryMakeState extends State<HistoryMake> {
  late Future<void> _refreshFuture;

  Stream<List<HistoryItem>> getHistoryStream() {
    if (widget.testData != null) {
      return Stream.value(widget.testData!);
    }
    return FirebaseFirestore.instance
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HistoryItem.fromFirestore(doc.data()))
        .toList());
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshFuture = Future.delayed(const Duration(milliseconds: 500));
    });
    await _refreshFuture;
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'add_location':
      case 'add_item':
        return Colors.greenAccent.shade400;
      case 'remove_location':
      case 'remove_item':
        return Colors.redAccent.shade200;
      case 'transfer':
        return Colors.blueAccent.shade400;
      default:
        return Colors.blueGrey.shade200;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'add_location':
        return Icons.add_location_alt;
      case 'remove_location':
        return Icons.location_off;
      case 'add_item':
        return Icons.add_box;
      case 'remove_item':
        return Icons.indeterminate_check_box;
      case 'transfer':
        return Icons.compare_arrows;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildExpandableTile(HistoryItem item, Size screenSize) {
    return Card(
      color: Colors.grey[900],
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.05,
          vertical: screenSize.height * 0.015,
        ),
        childrenPadding: EdgeInsets.only(
          left: screenSize.width * 0.12,
          bottom: screenSize.height * 0.01,
          right: screenSize.width * 0.05,
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        leading: CircleAvatar(
          backgroundColor: _getActionColor(item.action),
          child: Icon(_getActionIcon(item.action), color: Colors.black),
        ),
        title: Text(
          item.description,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenSize.width * 0.042,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _formatDateTime(item.timestamp),
          style: TextStyle(
            color: Colors.white54,
            fontSize: screenSize.width * 0.035,
          ),
        ),
        children: item.items?.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.white60),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${e['quantity']} ${e['name']}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenSize.width * 0.038,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList() ??
            [],
      ),
    );
  }

  Widget _buildStaticTile(HistoryItem item, Size screenSize) {
    return Card(
      color: Color(0XFF2E2E2E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.05,
          vertical: screenSize.height * 0.018,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: _getActionColor(item.action),
              child: Icon(_getActionIcon(item.action), color: Colors.black),
            ),
            SizedBox(width: screenSize.width * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenSize.width * 0.042,
                      fontWeight: FontWeight.w600,
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
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshFuture = Future.value();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E) ,
      appBar: SimpleAppBar(
        title: 'ACTION HISTORY',
        onBack: () => Navigator.pop(context),
        onProfile: () {},
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: Colors.greenAccent,
        backgroundColor: Colors.black,
        child: StreamBuilder<List<HistoryItem>>(
          stream: getHistoryStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading history',
                  style: TextStyle(color: Colors.redAccent, fontSize: 18),
                ),
              );
            }
            final historyItems = snapshot.data ?? [];
            if (historyItems.isEmpty) {
              return Center(
                child: Text(
                  'No history yet.',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              itemCount: historyItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = historyItems[index];
                final bool showExpandable = item.action == 'transfer' || item.action == 'remove_item';
                return showExpandable
                    ? _buildExpandableTile(item, screenSize)
                    : _buildStaticTile(item, screenSize);
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
